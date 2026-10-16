import AppKit
import CoreGraphics

// Original, vector-drawn TaskFire mark. Canvas coordinates are top-left based.
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
}
func gradient(_ colors: [CGColor]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
}
// A narrow flame edge hugs the complete T outline; tips stay short.
func flamingT() -> (CGPath, String) {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 276, y: 405))
    path.addCurve(to: CGPoint(x: 264, y: 365), control1: CGPoint(x: 266, y: 393), control2: CGPoint(x: 260, y: 378))
    path.addCurve(to: CGPoint(x: 278, y: 362), control1: CGPoint(x: 269, y: 378), control2: CGPoint(x: 279, y: 375))
    path.addLine(to: CGPoint(x: 278, y: 335))
    path.addCurve(to: CGPoint(x: 303, y: 305), control1: CGPoint(x: 278, y: 317), control2: CGPoint(x: 286, y: 305))
    path.addCurve(to: CGPoint(x: 309, y: 284), control1: CGPoint(x: 313, y: 305), control2: CGPoint(x: 315, y: 293))
    path.addCurve(to: CGPoint(x: 347, y: 304), control1: CGPoint(x: 327, y: 287), control2: CGPoint(x: 329, y: 304))
    path.addLine(to: CGPoint(x: 380, y: 304))
    path.addCurve(to: CGPoint(x: 400, y: 281), control1: CGPoint(x: 394, y: 304), control2: CGPoint(x: 403, y: 292))
    path.addCurve(to: CGPoint(x: 435, y: 304), control1: CGPoint(x: 419, y: 290), control2: CGPoint(x: 417, y: 304))
    path.addLine(to: CGPoint(x: 471, y: 304))
    path.addCurve(to: CGPoint(x: 492, y: 277), control1: CGPoint(x: 487, y: 304), control2: CGPoint(x: 496, y: 291))
    path.addCurve(to: CGPoint(x: 531, y: 304), control1: CGPoint(x: 514, y: 286), control2: CGPoint(x: 511, y: 304))
    path.addLine(to: CGPoint(x: 569, y: 304))
    path.addCurve(to: CGPoint(x: 590, y: 281), control1: CGPoint(x: 585, y: 304), control2: CGPoint(x: 594, y: 292))
    path.addCurve(to: CGPoint(x: 625, y: 304), control1: CGPoint(x: 610, y: 290), control2: CGPoint(x: 606, y: 304))
    path.addLine(to: CGPoint(x: 668, y: 304))
    path.addCurve(to: CGPoint(x: 688, y: 284), control1: CGPoint(x: 684, y: 304), control2: CGPoint(x: 692, y: 293))
    path.addCurve(to: CGPoint(x: 724, y: 305), control1: CGPoint(x: 707, y: 288), control2: CGPoint(x: 705, y: 304))
    path.addCurve(to: CGPoint(x: 748, y: 335), control1: CGPoint(x: 741, y: 305), control2: CGPoint(x: 748, y: 317))
    path.addLine(to: CGPoint(x: 748, y: 366))
    path.addCurve(to: CGPoint(x: 763, y: 381), control1: CGPoint(x: 748, y: 381), control2: CGPoint(x: 755, y: 388))
    path.addCurve(to: CGPoint(x: 744, y: 429), control1: CGPoint(x: 770, y: 400), control2: CGPoint(x: 755, y: 422))
    path.addCurve(to: CGPoint(x: 773, y: 428), control1: CGPoint(x: 754, y: 436), control2: CGPoint(x: 764, y: 434))
    path.addCurve(to: CGPoint(x: 732, y: 445), control1: CGPoint(x: 768, y: 447), control2: CGPoint(x: 748, y: 445))
    path.addLine(to: CGPoint(x: 594, y: 445))
    path.addCurve(to: CGPoint(x: 579, y: 465), control1: CGPoint(x: 584, y: 445), control2: CGPoint(x: 579, y: 454))
    path.addLine(to: CGPoint(x: 579, y: 497))
    path.addCurve(to: CGPoint(x: 593, y: 503), control1: CGPoint(x: 579, y: 510), control2: CGPoint(x: 589, y: 512))
    path.addCurve(to: CGPoint(x: 578, y: 544), control1: CGPoint(x: 600, y: 523), control2: CGPoint(x: 578, y: 528))
    path.addLine(to: CGPoint(x: 578, y: 578))
    path.addCurve(to: CGPoint(x: 593, y: 586), control1: CGPoint(x: 578, y: 592), control2: CGPoint(x: 591, y: 596))
    path.addCurve(to: CGPoint(x: 578, y: 629), control1: CGPoint(x: 601, y: 605), control2: CGPoint(x: 578, y: 612))
    path.addLine(to: CGPoint(x: 578, y: 672))
    path.addCurve(to: CGPoint(x: 593, y: 683), control1: CGPoint(x: 578, y: 687), control2: CGPoint(x: 588, y: 690))
    path.addCurve(to: CGPoint(x: 575, y: 714), control1: CGPoint(x: 595, y: 701), control2: CGPoint(x: 577, y: 706.2))
    path.addCurve(to: CGPoint(x: 541, y: 725.4), control1: CGPoint(x: 571, y: 723), control2: CGPoint(x: 554, y: 726.6))
    path.addCurve(to: CGPoint(x: 551, y: 739.2), control1: CGPoint(x: 550, y: 729.6), control2: CGPoint(x: 554, y: 735.6))
    path.addCurve(to: CGPoint(x: 511, y: 727.2), control1: CGPoint(x: 533, y: 738), control2: CGPoint(x: 525, y: 729))
    path.addCurve(to: CGPoint(x: 468, y: 726.6), control1: CGPoint(x: 495, y: 728.4), control2: CGPoint(x: 479, y: 730.2))
    path.addCurve(to: CGPoint(x: 442, y: 732.6), control1: CGPoint(x: 463, y: 732), control2: CGPoint(x: 451, y: 734.4))
    path.addCurve(to: CGPoint(x: 449, y: 708.6), control1: CGPoint(x: 447, y: 724.8), control2: CGPoint(x: 449, y: 718.2))
    path.addLine(to: CGPoint(x: 449, y: 670))
    path.addCurve(to: CGPoint(x: 434, y: 657), control1: CGPoint(x: 449, y: 657), control2: CGPoint(x: 440, y: 650))
    path.addCurve(to: CGPoint(x: 449, y: 613), control1: CGPoint(x: 427, y: 640), control2: CGPoint(x: 449, y: 628))
    path.addLine(to: CGPoint(x: 449, y: 572))
    path.addCurve(to: CGPoint(x: 432, y: 560), control1: CGPoint(x: 449, y: 558), control2: CGPoint(x: 439, y: 553))
    path.addCurve(to: CGPoint(x: 449, y: 517), control1: CGPoint(x: 425, y: 541), control2: CGPoint(x: 449, y: 533))
    path.addLine(to: CGPoint(x: 449, y: 465))
    path.addCurve(to: CGPoint(x: 430, y: 445), control1: CGPoint(x: 449, y: 452), control2: CGPoint(x: 442, y: 445))
    path.addLine(to: CGPoint(x: 302, y: 445))
    path.addCurve(to: CGPoint(x: 266, y: 428), control1: CGPoint(x: 285, y: 445), control2: CGPoint(x: 271, y: 439))
    path.addCurve(to: CGPoint(x: 276, y: 405), control1: CGPoint(x: 277, y: 432), control2: CGPoint(x: 285, y: 423))
    path.closeSubpath()
    return (path, "M276 405 C266 393 260 378 264 365 C269 378 279 375 278 362 L278 335 C278 317 286 305 303 305 C313 305 315 293 309 284 C327 287 329 304 347 304 L380 304 C394 304 403 292 400 281 C419 290 417 304 435 304 L471 304 C487 304 496 291 492 277 C514 286 511 304 531 304 L569 304 C585 304 594 292 590 281 C610 290 606 304 625 304 L668 304 C684 304 692 293 688 284 C707 288 705 304 724 305 C741 305 748 317 748 335 L748 366 C748 381 755 388 763 381 C770 400 755 422 744 429 C754 436 764 434 773 428 C768 447 748 445 732 445 L594 445 C584 445 579 454 579 465 L579 497 C579 510 589 512 593 503 C600 523 578 528 578 544 L578 578 C578 592 591 596 593 586 C601 605 578 612 578 629 L578 672 C578 687 588 690 593 683 C595 701 577 706.2 575 714 C571 723 554 726.6 541 725.4 C550 729.6 554 735.6 551 739.2 C533 738 525 729 511 727.2 C495 728.4 479 730.2 468 726.6 C463 732 451 734.4 442 732.6 C447 724.8 449 718.2 449 708.6 L449 670 C449 657 440 650 434 657 C427 640 449 628 449 613 L449 572 C449 558 439 553 432 560 C425 541 449 533 449 517 L449 465 C449 452 442 445 430 445 L302 445 C285 445 271 439 266 428 C277 432 285 423 276 405 Z")
}
func render(size: Int, url: URL) throws {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    ctx.translateBy(x: 0, y: 1024); ctx.scaleBy(x: 1, y: -1)
    let tile = CGPath(roundedRect: CGRect(x: 96, y: 96, width: 832, height: 832), cornerWidth: 187, cornerHeight: 187, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 8), blur: 18, color: color(90, 40, 15, 0.13))
    ctx.setFillColor(color(207, 94, 49)); ctx.addPath(tile); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState(); ctx.addPath(tile); ctx.clip()
    ctx.drawLinearGradient(gradient([color(235, 133, 77), color(215, 101, 56), color(187, 67, 36)]), start: CGPoint(x: 230, y: 110), end: CGPoint(x: 820, y: 940), options: [])
    ctx.restoreGState()
    ctx.addPath(tile); ctx.setStrokeColor(color(255, 235, 214, 0.28)); ctx.setLineWidth(2); ctx.strokePath()
    let flames = flamingT().0
    ctx.saveGState(); ctx.addPath(flames); ctx.clip()
    ctx.drawLinearGradient(gradient([color(255, 234, 173), color(255, 200, 107), color(255, 174, 77)]), start: CGPoint(x: 290, y: 180), end: CGPoint(x: 740, y: 850), options: [])
    ctx.restoreGState()
    // A clear ivory letter sits directly inside its flame-shaped outline.
    ctx.saveGState(); ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 5, color: color(115, 41, 18, 0.12))
    let letter = CGMutablePath()
    letter.addRoundedRect(in: CGRect(x: 463, y: 380, width: 102, height: 325), cornerWidth: 25, cornerHeight: 25)
    letter.addRoundedRect(in: CGRect(x: 292, y: 320, width: 440, height: 108), cornerWidth: 25, cornerHeight: 25)
    ctx.addPath(letter); ctx.setFillColor(color(255, 247, 233)); ctx.fillPath()
    ctx.restoreGState()
    let image = ctx.makeImage()!
    let bitmap = NSBitmapImageRep(cgImage: image)
    try bitmap.representation(using: .png, properties: [:])!.write(to: url)
}
let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("assets")
let iconset = assets.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for pointSize in [16, 32, 128, 256, 512] {
    try render(size: pointSize, url: iconset.appendingPathComponent("icon_\(pointSize)x\(pointSize).png"))
    try render(size: pointSize * 2, url: iconset.appendingPathComponent("icon_\(pointSize)x\(pointSize)@2x.png"))
}
try render(size: 1024, url: assets.appendingPathComponent("AppIcon.png"))
let svg = """
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <title>TaskFire — Flames following the T outline</title>
  <defs>
    <linearGradient id="tile" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#eb854d"/><stop offset=".5" stop-color="#d76538"/><stop offset="1" stop-color="#bb4324"/></linearGradient>
    <linearGradient id="fire" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#ffeaad"/><stop offset=".5" stop-color="#ffc86b"/><stop offset="1" stop-color="#ffae4d"/></linearGradient>
  </defs>
  <rect x="96" y="96" width="832" height="832" rx="187" fill="url(#tile)" stroke="#ffe4cc" stroke-opacity=".28" stroke-width="2"/>
  <path fill="url(#fire)" d="\(flamingT().1)"/>
  <g fill="#fff7e9"><rect x="463" y="380" width="102" height="325" rx="25"/><rect x="292" y="320" width="440" height="108" rx="25"/></g>
</svg>
"""
try Data(svg.utf8).write(to: assets.appendingPathComponent("AppIcon.svg"))
print("Rendered TaskFire T with flames along the letter outline at 16–1024 px")
