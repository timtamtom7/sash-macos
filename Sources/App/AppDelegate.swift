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

        SashState.shared.configure(store: sashStore)

        _ = CollaborationService.shared
        _ = EnterpriseService.shared
        _ = iOSCompanionService.shared
        SashAPIService.shared.start()

        setupStatusItem()
        setupPopover()
        setupShortcutMonitor()
        setupEventMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        SashAPIService.shared.stop()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "Sash")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

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

    private func setupShortcutMonitor() {
        shortcutMonitor = ShortcutMonitor()

        shortcutMonitor.onSnapPosition = { [weak self] position in
            self?.performSnap(position: position)
        }

        shortcutMonitor.start()
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover.isShown == true {
                self?.popover.performClose(nil)
            }
        }
    }

    private func performSnap(position: SnapPosition) {
        let windowManager = WindowManager.shared

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
            togglePopover()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.popover.isShown == true {
                    self?.popover.performClose(nil)
                }
            }
        } else {
            sashStore.refreshFocusedWindow()
        }

        showSnapOverlay(for: position)
    }

    private var overlayWindow: NSWindow?

    private func showSnapOverlay(for position: SnapPosition) {
        // Respect Reduce Motion accessibility setting
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return
        }

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

        let borderView = SnapBorderView(frame: NSRect(origin: .zero, size: frame.size))
        borderView.borderColor = NSColor.controlAccentColor
        borderView.borderWidth = 2
        borderView.fillColor = NSColor.controlAccentColor.withAlphaComponent(0.1)
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
