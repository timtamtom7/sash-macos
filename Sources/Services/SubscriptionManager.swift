import Foundation
import StoreKit

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case team = "team"
    case enterprise = "enterprise"

    var productId: String {
        switch self {
        case .free: return "com.sash.free"
        case .pro: return "com.sash.pro"
        case .team: return "com.sash.team"
        case .enterprise: return "com.sash.enterprise"
        }
    }

    var displayName: String {
        switch self {
        case .free: return "Sash Free"
        case .pro: return "Sash Pro"
        case .team: return "Sash Team"
        case .enterprise: return "Sash Enterprise"
        }
    }

    var price: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$3.99/mo or $29.99/yr"
        case .team: return "$7.99/mo or $59.99/yr"
        case .enterprise: return "Custom"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "1 synced folder",
                "Basic sync between 2 devices",
                "Manual sync (no automatic)",
                "7-day activity history",
                "Basic conflict resolution UI"
            ]
        case .pro:
            return [
                "Unlimited synced folders",
                "Automatic background sync",
                "ML-powered conflict resolution",
                "Unlimited device connections",
                "Unlimited activity history",
                "Priority sync queue",
                "Shortcuts integration",
                "Third-party cloud provider support",
                "Priority email support"
            ]
        case .team:
            return [
                "Everything in Pro",
                "Up to 10 team members per shared folder",
                "Real-time collaboration (presence, locking)",
                "Team activity feed",
                "Guest access",
                "File locking",
                "Change notifications",
                "Team admin controls"
            ]
        case .enterprise:
            return [
                "Everything in Team",
                "Unlimited team members",
                "SSO / SAML",
                "Audit logs",
                "DLP controls",
                "MDM support",
                "Custom data retention",
                "Dedicated account manager",
                "SLA guarantees"
            ]
        }
    }
}

// MARK: - Subscription Period

enum SubscriptionPeriod: String, Codable {
    case monthly = "monthly"
    case yearly = "yearly"

    var productId: String {
        switch self {
        case .monthly: return ".monthly"
        case .yearly: return ".yearly"
        }
    }
}

// MARK: - Subscription Manager

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var currentTier: SubscriptionTier = .free
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var purchaseError: String?
    @Published private(set) var isPurchasing: Bool = false
    @Published var hasActiveSubscription: Bool = false

    private var transactionListener: Task<Void, Error>?

    private let userDefaultsKey = "sash_subscription_tier"
    private let entitlementsKey = "sash_entitlements"

    private init() {
        loadCurrentTier()
        startTransactionListener()
        Task { await loadProducts() }
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIds = [
                SubscriptionTier.pro.productId + ".monthly",
                SubscriptionTier.pro.productId + ".yearly",
                SubscriptionTier.team.productId + ".monthly",
                SubscriptionTier.team.productId + ".yearly",
                SubscriptionTier.enterprise.productId + ".monthly"
            ]

            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ tier: SubscriptionTier, period: SubscriptionPeriod) async throws -> Bool {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        let productId = tier.productId + period.productId

        guard let product = products.first(where: { $0.id == productId }) else {
            purchaseError = "Product not found"
            return false
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            await updateCurrentTier(tier)
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            purchaseError = "Purchase is pending approval"
            return false

        default:
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updateTierFromTransactions()
        } catch {
            purchaseError = "Failed to restore: \(error.localizedDescription)"
        }
    }

    // MARK: - Transaction Listener

    private func startTransactionListener() {
        transactionListener = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                do {
                    let transaction = try Self.checkVerified(result)
                    await self.updateTierFromTransactions()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Update Tier from Transactions

    private func updateTierFromTransactions() async {
        var highestTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if let productId = transaction.productID as String?,
                   let tier = tierFromProductId(productId),
                   tier.rawValue > highestTier.rawValue {
                    highestTier = tier
                }
            }
        }

        await updateCurrentTier(highestTier)
    }

    // MARK: - Helpers

    private func tierFromProductId(_ productId: String) -> SubscriptionTier? {
        if productId.contains("pro") { return .pro }
        if productId.contains("team") { return .team }
        if productId.contains("enterprise") { return .enterprise }
        return nil
    }

    private func updateCurrentTier(_ tier: SubscriptionTier) async {
        currentTier = tier
        hasActiveSubscription = tier != .free
        saveCurrentTier()
    }

    private func saveCurrentTier() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: userDefaultsKey)
    }

    private func loadCurrentTier() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let tier = SubscriptionTier(rawValue: saved) {
            currentTier = tier
            hasActiveSubscription = tier != .free
        }
    }

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let signedType):
            return signedType
        }
    }

    // MARK: - Entitlements

    func hasEntitlement(_ feature: String) -> Bool {
        switch currentTier {
        case .free:
            return ["basic_sync", "conflict_ui"].contains(feature)
        case .pro:
            return [
                "unlimited_folders", "auto_sync", "ml_conflict", "unlimited_devices",
                "unlimited_history", "priority_queue", "shortcuts", "third_party_cloud",
                "priority_support"
            ].contains(feature)
        case .team:
            return true // includes all pro + team features
        case .enterprise:
            return true // all features
        }
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case verificationFailed
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        }
    }
}
