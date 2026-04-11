import Foundation

enum SnapResult {
    case success(SnapPosition?)
    case noFocusedWindow
    case cannotResize
    case accessibilityNotGranted
    
    var position: SnapPosition? {
        if case .success(let pos) = self {
            return pos
        }
        return nil
    }
}
