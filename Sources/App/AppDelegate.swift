import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var sashStore: SashStore!
    private var shortcutMonitor: ShortcutMonitor!
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        sashStore = SashStore()

        // Initialize SashState for shortcuts
        SashState.shared.configure(store: sashStore)

        setupStatusItem()
        setupPopover()
        setupShortcutMonitor()
        setupEventMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "Sash")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 340)
        popover.behavior = .transient
        popover.animates = true

        let contentView = SashPopoverView(sashStore: sashStore)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            sashStore.refreshFocusedWindow()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // MARK: - Shortcut Monitor

    private func setupShortcutMonitor() {
        shortcutMonitor = ShortcutMonitor()

        shortcutMonitor.onSnapPosition = { [weak self] position in
            self?.performSnap(position: position)
        }

        shortcutMonitor.start()
    }

    // MARK: - Event Monitor (for clicking outside to close popover)

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover.isShown == true {
                self?.popover.performClose(nil)
            }
        }
    }

    // MARK: - Snap Action

    private func performSnap(position: SnapPosition) {
        let windowManager = WindowManager.shared

        // Check accessibility permission first
        guard windowManager.isAccessibilityEnabled() else {
            sashStore.showAccessibilityAlert = true
            if !popover.isShown {
                togglePopover()
            }
            return
        }

        let result = windowManager.snapFocusedWindow(to: position)
        sashStore.lastSnapResult = result

        if !popover.isShown {
            // Show brief visual feedback
            togglePopover()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.popover.isShown == true {
                    self?.popover.performClose(nil)
                }
            }
        } else {
            // Refresh to show updated status
            sashStore.refreshFocusedWindow()
        }

        // Show overlay
        showSnapOverlay(for: position)
    }

    // MARK: - Snap Overlay

    private var overlayWindow: NSWindow?

    private func showSnapOverlay(for position: SnapPosition) {
        overlayWindow?.orderOut(nil)

        guard let screen = NSScreen.main else { return }

        let frame = calculateFrame(for: position, on: screen)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = true

        // Create a border view
        let borderView = SnapBorderView(frame: NSRect(origin: .zero, size: frame.size))
        borderView.borderColor = NSColor(Theme.Colors.accent)
        borderView.borderWidth = 2
        borderView.fillColor = NSColor(Theme.Colors.accent).withAlphaComponent(0.1)
        window.contentView = borderView

        overlayWindow = window
        window.orderFront(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.overlayWindow?.contentView?.animator().alphaValue = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.overlayWindow?.orderOut(nil)
            }
        }
    }

    private func calculateFrame(for position: SnapPosition, on screen: NSScreen) -> NSRect {
        let visibleFrame = screen.visibleFrame
        let menuBarHeight = (screen.frame.height - visibleFrame.height - (screen.safeAreaInsets.bottom > 0 ? 0 : 24))

        switch position {
        case .leftHalf:
            return NSRect(
                x: visibleFrame.origin.x,
                y: menuBarHeight,
                width: visibleFrame.width / 2,
                height: visibleFrame.height
            )
        case .rightHalf:
            return NSRect(
                x: visibleFrame.origin.x + visibleFrame.width / 2,
                y: menuBarHeight,
                width: visibleFrame.width / 2,
                height: visibleFrame.height
            )
        case .topHalf:
            return NSRect(
                x: visibleFrame.origin.x,
                y: menuBarHeight + visibleFrame.height / 2,
                width: visibleFrame.width,
                height: visibleFrame.height / 2
            )
        case .bottomHalf:
            return NSRect(
                x: visibleFrame.origin.x,
                y: menuBarHeight,
                width: visibleFrame.width,
                height: visibleFrame.height / 2
            )
        case .fullScreen:
            return NSRect(
                x: visibleFrame.origin.x,
                y: menuBarHeight,
                width: visibleFrame.width,
                height: visibleFrame.height
            )
        case .center:
            let centerWidth = visibleFrame.width * 0.7
            let centerHeight = visibleFrame.height * 0.7
            return NSRect(
                x: visibleFrame.origin.x + (visibleFrame.width - centerWidth) / 2,
                y: menuBarHeight + (visibleFrame.height - centerHeight) / 2,
                width: centerWidth,
                height: centerHeight
            )
        }
    }
}

// MARK: - SnapBorderView

class SnapBorderView: NSView {
    var borderColor: NSColor = .blue
    var borderWidth: CGFloat = 2
    var fillColor: NSColor = .clear

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        fillColor.setFill()
        dirtyRect.fill()

        borderColor.setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
        path.lineWidth = borderWidth
        path.stroke()
    }
}

// MARK: - SashStore

class SashStore: ObservableObject {
    @Published var focusedAppName: String = "No focused app"
    @Published var focusedWindowTitle: String = ""
    @Published var lastSnapPosition: SnapPosition?
    @Published var lastSnapResult: SnapResult = .success(nil)
    @Published var showAccessibilityAlert: Bool = false
    @Published var launchAtLogin: Bool = false
    @Published var snapPresets: [SnapPreset] = []
    @Published var monitors: [MonitorInfo] = []

    private let windowManager = WindowManager.shared
    private let presetsKey = "sash_presets"

    init() {
        loadPresets()
        refreshMonitors()
    }

    func refreshFocusedWindow() {
        if let app = NSWorkspace.shared.frontmostApplication {
            focusedAppName = app.localizedName ?? "Unknown"
        } else {
            focusedAppName = "No focused app"
        }
    }

    func refreshMonitors() {
        monitors = MonitorManager.shared.getMonitors()
    }

    func addPreset(_ preset: SnapPreset) {
        snapPresets.append(preset)
        savePresets()
    }

    func deletePreset(_ id: UUID) {
        snapPresets.removeAll { $0.id == id }
        savePresets()
    }

    private func savePresets() {
        // Simplified - just use array directly
    }

    private func loadPresets() {
        // Simplified - presets managed in-memory
        snapPresets = []
    }
}

// MARK: - SnapResult

enum SnapResult {
    case success(SnapPosition?)
    case noFocusedWindow
    case cannotResize
    case accessibilityNotGranted
}

// MARK: - Window Arrangement Preset

struct SnapPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var positions: [PresetPosition]

    struct PresetPosition: Codable {
        var bundleIdentifier: String
        var snapPosition: String
    }

    init(id: UUID = UUID(), name: String, positions: [PresetPosition] = []) {
        self.id = id
        self.name = name
        self.positions = positions
    }
}

// MARK: - SashState

@MainActor
final class SashState {
    static let shared = SashState()

    var store: SashStore?
    var presets: [SnapPreset] {
        get { store?.snapPresets ?? [] }
        set {
            store?.snapPresets = newValue
        }
    }

    private init() {}

    func configure(store: SashStore) {
        self.store = store
    }
}
