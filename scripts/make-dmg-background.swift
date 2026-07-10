// Renders the installer DMG background at @1x and @2x.
// Premium dark canvas: brand header, a glowing arrow from the app to the
// Applications folder, and a footer hint. Icons themselves are placed on top
// by create-dmg; this only draws the frame around them.
import AppKit

// Window is 660x460; icons sit centered at y=250 (app x=170, Applications x=490).
let W: CGFloat = 660
let H: CGFloat = 460

func hex(_ s: String, _ a: CGFloat = 1) -> NSColor {
    var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
                   green: CGFloat((v >> 8) & 0xff) / 255,
                   blue: CGFloat(v & 0xff) / 255, alpha: a)
}

func render(scale: CGFloat, to url: URL) {
    let px = Int(W * scale), py = Int(H * scale)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: py,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: W, height: H)
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let g = ctx.cgContext
    // Native bottom-left origin (text draws upright). `t(y)` converts a
    // top-left y (matching create-dmg's icon layout) to this space.
    func t(_ y: CGFloat) -> CGFloat { H - y }

    // Base vertical gradient — lighter at top, near-black at the bottom.
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [hex("0C0C10").cgColor, hex("15151A").cgColor, hex("26262E").cgColor] as CFArray,
        locations: [0, 0.45, 1])!
    g.drawLinearGradient(grad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: H), options: [])

    // Soft teal glow behind the app icon (left slot, icon center top-y=250).
    let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [hex("4FD6C8", 0.20).cgColor, hex("4FD6C8", 0).cgColor] as CFArray,
        locations: [0, 1])!
    g.drawRadialGradient(glow, startCenter: CGPoint(x: 170, y: t(250)), startRadius: 0,
                         endCenter: CGPoint(x: 170, y: t(250)), endRadius: 200, options: [])

    // Hairline inner border for a machined edge.
    hex("FFFFFF", 0.06).setStroke()
    let border = NSBezierPath(roundedRect: NSRect(x: 6, y: 6, width: W - 12, height: H - 12),
                              xRadius: 12, yRadius: 12)
    border.lineWidth = 1
    border.stroke()

    // Draw text centered horizontally, with `topY` being the distance from the
    // top of the canvas to the text's top edge.
    func draw(_ s: String, _ font: NSFont, _ color: NSColor, topY: CGFloat) {
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let str = NSAttributedString(string: s, attributes: attr)
        let sz = str.size()
        str.draw(at: NSPoint(x: (W - sz.width) / 2, y: t(topY) - sz.height))
    }

    // Header wordmark + tagline.
    draw("SideTerminal", NSFont.systemFont(ofSize: 30, weight: .bold), hex("FFFFFF"), topY: 44)
    draw("Your terminal, one edge away.",
         NSFont.systemFont(ofSize: 13, weight: .medium), hex("9A9AA2"), topY: 84)

    // Glowing arrow from the app toward the Applications folder (icon center y=250).
    let ay = t(250)
    let arrow = NSBezierPath()
    arrow.lineWidth = 3
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: 285, y: ay))
    arrow.line(to: NSPoint(x: 375, y: ay))
    arrow.move(to: NSPoint(x: 358, y: ay - 12))
    arrow.line(to: NSPoint(x: 375, y: ay))
    arrow.line(to: NSPoint(x: 358, y: ay + 12))
    hex("4FD6C8", 0.9).setStroke()
    arrow.stroke()

    // Footer hint.
    draw("Drag SideTerminal onto the Applications folder to install",
         NSFont.systemFont(ofSize: 12, weight: .regular), hex("6E6E77"), topY: 410)

    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    print("background \(px)x\(py) -> \(url.lastPathComponent)")
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
render(scale: 1, to: out.appendingPathComponent("dmg-background.png"))
render(scale: 2, to: out.appendingPathComponent("dmg-background@2x.png"))
