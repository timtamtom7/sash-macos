import SwiftUI

struct SnapPositionRow: View {
    let position: SnapPosition
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: position.icon)
                .font(.system(size: 16))
                .frame(width: 24, height: 24)
                .glassIcon(Theme.Colors.accentPrimary)

            Text(position.rawValue)
                .font(Theme.Typography.body)
                .foregroundColor(.primary)
                .accessibilityLabel(position.rawValue)

            Spacer()

            shortcutBadge
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(Theme.Animation.fast) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(position.description)
        .accessibilityAddTraits(.isButton)
    }

    private var shortcutBadge: some View {
        Text(position.shortcut)
            .font(Theme.Typography.shortcut)
            .foregroundColor(.secondary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}
