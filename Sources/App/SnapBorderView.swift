import AppKit

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
