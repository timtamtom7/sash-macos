import AppKit
import ApplicationServices

class WindowManager {
    static let shared = WindowManager()

    private init() {}

    // MARK: - Accessibility Check

    func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Snap Focused Window

    func snapFocusedWindow(to position: SnapPosition) -> SnapResult {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return .noFocusedWindow
        }

        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

        guard result == .success, let windowElement = focusedWindow else {
            return .noFocusedWindow
        }

        // swiftlint:disable:next force_cast
        let window = windowElement as! AXUIElement
        guard let screen = NSScreen.main else { return .noFocusedWindow }

        let frame = calculateFrame(for: position, on: screen)
        return setWindowFrame(window, to: frame)
    }

    // MARK: - Frame Calculation

    func calculateFrame(for position: SnapPosition, on screen: NSScreen) -> CGRect {
        let visibleFrame = screen.visibleFrame
        let menuBarHeight = screen.frame.height - visibleFrame.height - visibleFrame.origin.y

        switch position {
        case .leftHalf:
            return CGRect(
                x: visibleFrame.origin.x,
                y: menuBarHeight,
                width: visibleFrame.width / 2,
                height: visibleFrame.height
            )
        case .rightHalf:
            return CGRect(
                x: visibleFrame.origin.x + visibleFrame.width / 2,
                y: menuBarHeight,
                width: visibleFrame.width / 2,
                height: visibleFrame.height
            )
        case .topHalf:
            return CGRect(
                x: visibleFrame.origin.x,
                y: menuBarHeight + visibleFrame.height / 2,
                width: visibleFrame.width,
                height: visibleFrame.height / 2
            )
        case .bottomHalf:
            return CGRect(
                x: visibleFrame.origin.x,
                y: menuBarHeight,
                width: visibleFrame.width,
                height: visibleFrame.height / 2
            )
        case .fullScreen:
            return CGRect(
                x: visibleFrame.origin.x,
                y: menuBarHeight,
                width: visibleFrame.width,
                height: visibleFrame.height
            )
        case .center:
            let centerWidth = visibleFrame.width * 0.7
            let centerHeight = visibleFrame.height * 0.7
            return CGRect(
                x: visibleFrame.origin.x + (visibleFrame.width - centerWidth) / 2,
                y: menuBarHeight + (visibleFrame.height - centerHeight) / 2,
                width: centerWidth,
                height: centerHeight
            )
        }
    }

    // MARK: - Set Window Frame

    private func setWindowFrame(_ window: AXUIElement, to frame: CGRect) -> SnapResult {
        // Position
        var position = CGPoint(x: frame.origin.x, y: frame.origin.y)
        guard let positionValue = AXValueCreate(.cgPoint, &position) else {
            return .cannotResize
        }

        let posResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        if posResult != .success {
            return .cannotResize
        }

        // Size
        var size = CGSize(width: frame.width, height: frame.height)
        guard let sizeValue = AXValueCreate(.cgSize, &size) else {
            return .cannotResize
        }

        let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        if sizeResult != .success {
            return .cannotResize
        }

        return .success(nil)
    }

    // MARK: - Get Window Info

    func getFocusedWindowInfo() -> (appName: String, windowTitle: String)? {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

        guard result == .success, let windowElement = focusedWindow else {
            return nil
        }

        // swiftlint:disable:next force_cast
        let window = windowElement as! AXUIElement

        var title: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)

        let windowTitle = (title as? String) ?? ""
        let appName = app.localizedName ?? "Unknown"

        return (appName, windowTitle)
    }
}
