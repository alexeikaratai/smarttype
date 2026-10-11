// Draws SmartType's app icon and writes it as an .icns. Run by `make icon`, which `make app`
// depends on; the .icns is generated, never committed.
//
// Usage: swift scripts/generate-icon.swift <output.icns>
//
// One key with two legends, F and А: the same key types either, depending on the layout that
// is on, and that is the whole problem SmartType fixes. Dark, like SmartDock's icon.
//
// Every size is drawn into a bitmap of exactly that many pixels. Drawing into an NSImage with
// lockFocus renders at the screen's scale instead, so on a Retina Mac each PNG comes out twice
// the size its name says.

import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    print("usage: swift scripts/generate-icon.swift <output.icns>")
    exit(2)
}

struct IconError: Error, CustomStringConvertible {
    let description: String
}

// MARK: - Drawing

/// The macOS icon grid: an 824-point body on a 1024-point canvas, corners at 22.5 %.
func body(_ side: CGFloat) -> NSBezierPath {
    let inset = side * 0.098
    let rect = NSRect(x: inset, y: inset * 1.1, width: side - inset * 2, height: side - inset * 2)
    return NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)
}

func legend(_ letter: String, side: CGFloat, color: NSColor, center: NSPoint) {
    var font = NSFont.systemFont(ofSize: side * 0.2, weight: .semibold)
    if let rounded = font.fontDescriptor.withDesign(.rounded) {
        font = NSFont(descriptor: rounded, size: side * 0.2) ?? font
    }
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let size = (letter as NSString).size(withAttributes: attributes)
    (letter as NSString).draw(
        at: NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2), withAttributes: attributes)
}

func drawIcon(side: CGFloat) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowOffset = NSSize(width: 0, height: -side * 0.01)
    shadow.shadowBlurRadius = side * 0.02
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor.black.setFill()
    body(side).fill()
    NSGraphicsContext.restoreGraphicsState()

    let slate = NSGradient(
        starting: NSColor(red: 0.18, green: 0.20, blue: 0.27, alpha: 1),
        ending: NSColor(red: 0.08, green: 0.09, blue: 0.13, alpha: 1))
    slate?.draw(in: body(side), angle: -90)

    // The key, with a darker edge under it so it reads as raised.
    let key = NSRect(x: side * 0.25, y: side * 0.26, width: side * 0.5, height: side * 0.48)
    let radius = side * 0.07
    NSColor(white: 0.62, alpha: 1).setFill()
    NSBezierPath(roundedRect: key.offsetBy(dx: 0, dy: -side * 0.025), xRadius: radius, yRadius: radius).fill()
    let keyTop = NSGradient(starting: NSColor(white: 0.99, alpha: 1), ending: NSColor(white: 0.87, alpha: 1))
    keyTop?.draw(in: NSBezierPath(roundedRect: key, xRadius: radius, yRadius: radius), angle: -90)

    legend(
        "F", side: side, color: NSColor(white: 0.15, alpha: 1),
        center: NSPoint(x: key.minX + key.width * 0.32, y: key.maxY - key.height * 0.3))
    legend(
        "А", side: side, color: NSColor(red: 0.20, green: 0.48, blue: 1.00, alpha: 1),
        center: NSPoint(x: key.minX + key.width * 0.68, y: key.minY + key.height * 0.3))
}

func png(pixels: Int) throws -> Data {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
    else { throw IconError(description: "no \(pixels)-pixel bitmap") }
    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    drawIcon(side: CGFloat(pixels))
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw IconError(description: "no PNG at \(pixels) pixels")
    }
    return data
}

// MARK: - The .icns

let files = FileManager.default
let iconset = files.temporaryDirectory.appending(path: "SmartType-\(UUID().uuidString).iconset")
do {
    try files.createDirectory(at: iconset, withIntermediateDirectories: true)
    defer { try? files.removeItem(at: iconset) }
    for points in [16, 32, 128, 256, 512] {
        try png(pixels: points).write(to: iconset.appending(path: "icon_\(points)x\(points).png"))
        try png(pixels: points * 2).write(to: iconset.appending(path: "icon_\(points)x\(points)@2x.png"))
    }
    let iconutil = Process()
    iconutil.executableURL = URL(filePath: "/usr/bin/iconutil")
    iconutil.arguments = ["-c", "icns", iconset.path, "-o", arguments[1]]
    try iconutil.run()
    iconutil.waitUntilExit()
    guard iconutil.terminationStatus == 0 else {
        throw IconError(description: "iconutil exited with \(iconutil.terminationStatus)")
    }
    print("✅ \(arguments[1])")
} catch {
    print("❌ \(error)")
    exit(1)
}
