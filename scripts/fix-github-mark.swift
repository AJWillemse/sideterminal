// Converts the black-on-white GitHub mark into a proper template image:
// black shape, real alpha (whiteness becomes transparency).
import AppKit

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])

guard let source = NSImage(contentsOf: input),
      let tiff = source.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff) else {
    fatalError("cannot read \(input.path)")
}

let width = rep.pixelsWide
let height = rep.pixelsHigh
let out = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!

for y in 0..<height {
    for x in 0..<width {
        let c = rep.colorAt(x: x, y: y) ?? .white
        let rgb = c.usingColorSpace(.deviceRGB) ?? c
        // Luminance → inverse alpha: white background disappears, the
        // dark mark stays at full strength, edges stay anti-aliased.
        let lum = 0.2126 * rgb.redComponent
                + 0.7152 * rgb.greenComponent
                + 0.0722 * rgb.blueComponent
        let alpha = (1.0 - lum) * rgb.alphaComponent
        out.setColor(
            NSColor(deviceRed: 0, green: 0, blue: 0, alpha: alpha),
            atX: x, y: y
        )
    }
}

try! out.representation(using: .png, properties: [:])!.write(to: output)
print("mark OK \(width)x\(height)")
