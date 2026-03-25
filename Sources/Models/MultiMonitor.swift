import Foundation
import AppKit

// MARK: - Monitor Info

struct MonitorInfo: Identifiable, Codable, Hashable {
    let id: UUID
    let displayId: UInt32
    let name: String
    let width: CGFloat
    let height: CGFloat
    let originX: CGFloat
    let originY: CGFloat
    let isMain: Bool

    init(displayId: UInt32, name: String, width: CGFloat, height: CGFloat, originX: CGFloat, originY: CGFloat, isMain: Bool = false) {
        self.id = UUID()
        self.displayId = displayId
        self.name = name
        self.width = width
        self.height = height
        self.originX = originX
        self.originY = originY
        self.isMain = isMain
    }

    var frame: CGRect {
        CGRect(x: originX, y: originY, width: width, height: height)
    }
}

// MARK: - Window Arrangement Preset

struct WindowArrangementPreset: Identifiable {
    let id: UUID
    var name: String
    var windows: [ArrangedWindow]
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        windows: [ArrangedWindow] = [],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.windows = windows
        self.isEnabled = isEnabled
    }
}

struct ArrangedWindow: Identifiable {
    let id: UUID
    var bundleIdentifier: String?
    var positionRaw: String
    var monitorIndex: Int
    var widthFraction: Double
    var heightFraction: Double

    init(
        id: UUID = UUID(),
        bundleIdentifier: String? = nil,
        position: SnapPosition,
        monitorIndex: Int = 0,
        widthFraction: Double = 0.5,
        heightFraction: Double = 1.0
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.positionRaw = position.rawValue
        self.monitorIndex = monitorIndex
        self.widthFraction = widthFraction
        self.heightFraction = heightFraction
    }

    var position: SnapPosition {
        SnapPosition(rawValue: positionRaw) ?? .leftHalf
    }
}

// MARK: - Monitor Manager

final class MonitorManager {
    static let shared = MonitorManager()

    private init() {}

    func getMonitors() -> [MonitorInfo] {
        var monitors: [MonitorInfo] = []

        for screen in NSScreen.screens {
            let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? 0
            let name = screen.localizedName
            let width = screen.frame.width
            let height = screen.frame.height
            let originX = screen.frame.origin.x
            let originY = screen.frame.origin.y
            let isMain = screen == NSScreen.main

            monitors.append(MonitorInfo(
                displayId: displayID,
                name: name,
                width: width,
                height: height,
                originX: originX,
                originY: originY,
                isMain: isMain
            ))
        }

        return monitors
    }

    func getMainMonitor() -> MonitorInfo? {
        return getMonitors().first { $0.isMain }
    }

    func monitorCount() -> Int {
        NSScreen.screens.count
    }

    func calculateFrame(
        for position: SnapPosition,
        on monitor: MonitorInfo,
        widthFraction: Double = 1.0,
        heightFraction: Double = 1.0
    ) -> CGRect {
        let visibleFrame = monitor.frame

        switch position {
        case .leftHalf:
            return CGRect(
                x: visibleFrame.origin.x,
                y: visibleFrame.origin.y,
                width: visibleFrame.width * 0.5 * widthFraction,
                height: visibleFrame.height * heightFraction
            )
        case .rightHalf:
            return CGRect(
                x: visibleFrame.origin.x + visibleFrame.width * 0.5,
                y: visibleFrame.origin.y,
                width: visibleFrame.width * 0.5 * widthFraction,
                height: visibleFrame.height * heightFraction
            )
        case .topHalf:
            return CGRect(
                x: visibleFrame.origin.x,
                y: visibleFrame.origin.y + visibleFrame.height * 0.5,
                width: visibleFrame.width * widthFraction,
                height: visibleFrame.height * 0.5 * heightFraction
            )
        case .bottomHalf:
            return CGRect(
                x: visibleFrame.origin.x,
                y: visibleFrame.origin.y,
                width: visibleFrame.width * widthFraction,
                height: visibleFrame.height * 0.5 * heightFraction
            )
        case .fullScreen:
            return CGRect(
                x: visibleFrame.origin.x,
                y: visibleFrame.origin.y,
                width: visibleFrame.width * widthFraction,
                height: visibleFrame.height * heightFraction
            )
        case .center:
            let w = visibleFrame.width * 0.7 * widthFraction
            let h = visibleFrame.height * 0.7 * heightFraction
            return CGRect(
                x: visibleFrame.origin.x + (visibleFrame.width - w) / 2,
                y: visibleFrame.origin.y + (visibleFrame.height - h) / 2,
                width: w,
                height: h
            )
        }
    }
}
