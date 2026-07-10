// Renders the monochrome menu-bar template icon: the app icon's motif
// (sidebar strip + prompt) as pure black shapes on transparency.
import AppKit

func draw(size: CGFloat, scale: CGFloat, to url: URL) {
    let px = Int(size * scale)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    // rep.size already maps the 18pt user space onto the pixel grid.
    NSColor.black.set()

    let line: CGFloat = 1.6
    let frame = CGRect(x: 1.2, y: 2.0, width: size - 2.4, height: size - 4.0)

    // Rounded-square outline.
    let outline = NSBezierPath(roundedRect: frame, xRadius: 4.2, yRadius: 4.2)
    outline.lineWidth = line
    outline.stroke()

    // Filled sidebar strip on the left, echoing the app icon's glowing edge.
    let strip = CGRect(x: frame.minX + 2.4, y: frame.minY + 2.4,
                       width: 3.4, height: frame.height - 4.8)
    NSBezierPath(roundedRect: strip, xRadius: 1.6, yRadius: 1.6).fill()

    // Prompt chevron + underscore.
    let chevron = NSBezierPath()
    chevron.lineWidth = line
    chevron.lineCapStyle = .round
    chevron.lineJoinStyle = .round
    let cx = frame.minX + 8.6
    let cy = frame.midY
    chevron.move(to: NSPoint(x: cx, y: cy + 2.6))
    chevron.line(to: NSPoint(x: cx + 2.8, y: cy))
    chevron.line(to: NSPoint(x: cx, y: cy - 2.6))
    chevron.stroke()

    let dash = NSBezierPath()
    dash.lineWidth = line
    dash.lineCapStyle = .round
    dash.move(to: NSPoint(x: cx + 4.2, y: cy - 2.6))
    dash.line(to: NSPoint(x: cx + 6.6, y: cy - 2.6))
    dash.stroke()

    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
draw(size: 18, scale: 1, to: out.appendingPathComponent("MenuBarIcon.png"))
draw(size: 18, scale: 2, to: out.appendingPathComponent("MenuBarIcon@2x.png"))
print("menu bar icon OK")
