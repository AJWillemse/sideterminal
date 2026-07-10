// Generates AppIcon.icns: a macOS-style rounded-square icon showing a
// terminal sidebar docked to the right screen edge with a glowing prompt.
// Usage: swift make-icon.swift <output-dir>
import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let ctx = NSGraphicsContext.current?.cgContext else { return image }
    let s = size / 1024.0

    // Canvas: macOS icon grid — rounded square with margin.
    let inset = 100 * s
    let rect = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let radius = 185 * s
    let square = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Deep space-gray vertical gradient.
    ctx.saveGState()
    ctx.addPath(square)
    ctx.clip()
    let bg = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            CGColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1),
            CGColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 1),
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        bg,
        start: CGPoint(x: rect.midX, y: rect.maxY),
        end: CGPoint(x: rect.midX, y: rect.minY),
        options: []
    )

    // Faint "screen" field on the left to imply the desktop.
    let screenRect = rect.insetBy(dx: 90 * s, dy: 130 * s)

    // Sidebar card docked to the right of the screen field.
    let cardWidth = screenRect.width * 0.46
    let cardRect = CGRect(
        x: screenRect.maxX - cardWidth,
        y: screenRect.minY,
        width: cardWidth,
        height: screenRect.height
    )
    let cardRadius = 64 * s
    let card = CGPath(roundedRect: cardRect, cornerWidth: cardRadius, cornerHeight: cardRadius, transform: nil)

    // Card shadow.
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: -14 * s, height: -10 * s),
        blur: 60 * s,
        color: CGColor(gray: 0, alpha: 0.55)
    )
    ctx.addPath(card)
    ctx.setFillColor(CGColor(red: 0.13, green: 0.14, blue: 0.17, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Card inner gradient + hairline.
    ctx.saveGState()
    ctx.addPath(card)
    ctx.clip()
    let cardGrad = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            CGColor(red: 0.22, green: 0.24, blue: 0.28, alpha: 1),
            CGColor(red: 0.13, green: 0.14, blue: 0.17, alpha: 1),
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        cardGrad,
        start: CGPoint(x: cardRect.midX, y: cardRect.maxY),
        end: CGPoint(x: cardRect.midX, y: cardRect.minY),
        options: []
    )
    ctx.restoreGState()
    ctx.addPath(card)
    ctx.setStrokeColor(CGColor(gray: 1.0, alpha: 0.10))
    ctx.setLineWidth(3 * s)
    ctx.strokePath()

    // Prompt glyph "❯" + cursor block inside the card.
    let glyphY = cardRect.maxY - cardRect.height * 0.30
    let chevron = CGMutablePath()
    let cx = cardRect.minX + cardRect.width * 0.16
    let ch = 60 * s
    chevron.move(to: CGPoint(x: cx, y: glyphY + ch))
    chevron.addLine(to: CGPoint(x: cx + ch * 0.9, y: glyphY))
    chevron.addLine(to: CGPoint(x: cx, y: glyphY - ch))
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 26 * s, color: CGColor(red: 0.35, green: 0.78, blue: 1.0, alpha: 0.9))
    ctx.addPath(chevron)
    ctx.setStrokeColor(CGColor(red: 0.42, green: 0.80, blue: 1.0, alpha: 1))
    ctx.setLineWidth(26 * s)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()

    // Cursor block.
    let cursor = CGRect(
        x: cx + ch * 1.35,
        y: glyphY - 26 * s,
        width: 78 * s,
        height: 40 * s
    )
    ctx.addPath(CGPath(roundedRect: cursor, cornerWidth: 8 * s, cornerHeight: 8 * s, transform: nil))
    ctx.setFillColor(CGColor(red: 0.42, green: 0.80, blue: 1.0, alpha: 0.95))
    ctx.fillPath()
    ctx.restoreGState()

    // Subtle text lines below the prompt.
    ctx.setFillColor(CGColor(gray: 1.0, alpha: 0.16))
    for i in 0..<3 {
        let y = glyphY - (140 + CGFloat(i) * 90) * s
        let w = cardRect.width * (0.62 - CGFloat(i) * 0.13)
        let line = CGRect(x: cx, y: y, width: w, height: 26 * s)
        ctx.addPath(CGPath(roundedRect: line, cornerWidth: 13 * s, cornerHeight: 13 * s, transform: nil))
        ctx.fillPath()
    }

    ctx.restoreGState()
    return image
}

let iconset = "\(outDir)/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

for (name, px) in [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
] {
    let img = drawIcon(size: CGFloat(px))
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { continue }
    rep.size = NSSize(width: px, height: px)
    guard let png = rep.representation(using: .png, properties: [:]) else { continue }
    try! png.write(to: URL(fileURLWithPath: "\(iconset)/\(name).png"))
}
print("iconset written to \(iconset)")
