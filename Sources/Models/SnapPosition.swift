import Foundation
import SwiftUI

enum SnapPosition: String, CaseIterable, Identifiable {
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case topHalf = "Top Half"
    case bottomHalf = "Bottom Half"
    case fullScreen = "Full Screen"
    case center = "Center"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .fullScreen: return "rectangle.fill"
        case .center: return "rectangle.center.inset.filled"
        }
    }

    var shortcut: String {
        switch self {
        case .leftHalf: return "⌘⌥←"
        case .rightHalf: return "⌘⌥→"
        case .topHalf: return "⌘⌥↑"
        case .bottomHalf: return "⌘⌥↓"
        case .fullScreen: return "⌘⌥F"
        case .center: return "⌘⌥C"
        }
    }

    var keyEquivalent: String {
        switch self {
        case .leftHalf: return "←"
        case .rightHalf: return "→"
        case .topHalf: return "↑"
        case .bottomHalf: return "↓"
        case .fullScreen: return "f"
        case .center: return "c"
        }
    }

    var modifiers: NSEvent.ModifierFlags {
        return [.command, .option]
    }

    var description: String {
        switch self {
        case .leftHalf: return "Snap to left half of screen"
        case .rightHalf: return "Snap to right half of screen"
        case .topHalf: return "Snap to top half of screen"
        case .bottomHalf: return "Snap to bottom half of screen"
        case .fullScreen: return "Snap to full screen"
        case .center: return "Center window on screen"
        }
    }
}
