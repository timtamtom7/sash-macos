import AppKit
import Carbon

class ShortcutMonitor {
    var onSnapPosition: ((SnapPosition) -> Void)?

    private var eventMonitor: Any?
    private var globalMonitor: Any?

    func start() {
        // Local monitor for key events when app is focused
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyEvent(event)
        }

        // Global monitor for key events even when app is not focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
    }

    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let expectedModifiers: NSEvent.ModifierFlags = [.command, .option]

        guard modifiers == expectedModifiers else {
            return event
        }

        let key = event.keyCode

        // Arrow keys
        switch key {
        case 123: // Left arrow
            onSnapPosition?(.leftHalf)
            return nil
        case 124: // Right arrow
            onSnapPosition?(.rightHalf)
            return nil
        case 126: // Up arrow
            onSnapPosition?(.topHalf)
            return nil
        case 125: // Down arrow
            onSnapPosition?(.bottomHalf)
            return nil
        default:
            break
        }

        // Character keys
        if let characters = event.charactersIgnoringModifiers?.lowercased() {
            switch characters {
            case "f":
                onSnapPosition?(.fullScreen)
                return nil
            case "c":
                onSnapPosition?(.center)
                return nil
            default:
                break
            }
        }

        return event
    }

    deinit {
        stop()
    }
}
