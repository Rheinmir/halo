import SwiftUI

/// Icon app: khối vuông bo góc tối, vòng 6 chấm màu quanh một tâm sáng, một chấm đang "được chọn".
struct AppIcon: View {
    private let colors: [Color] = [.blue, .purple, .pink, .orange, .yellow, .green]
    var body: some View {
        let s: CGFloat = 1024
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.225, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.22), Color(white: 0.06)], startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.82, height: s * 0.82)
                .shadow(color: .black.opacity(0.35), radius: s * 0.02, y: s * 0.012)
            Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: s * 0.012).frame(width: s * 0.62)
            Wedge(index: 0, count: 6).fill(Color.blue.opacity(0.28)).frame(width: s * 0.62, height: s * 0.62)
            ForEach(0..<6, id: \.self) { i in
                let a = Double(i) * .pi / 3
                Circle().fill(colors[i].gradient)
                    .frame(width: s * (i == 0 ? 0.135 : 0.105))
                    .offset(x: s * 0.21 * sin(a), y: -s * 0.21 * cos(a))
            }
            Circle().fill(Color.white.opacity(0.9)).frame(width: s * 0.06)
        }
        .frame(width: s, height: s)
    }
}

@MainActor func writeIcon(to path: String) {
    let r = ImageRenderer(content: AppIcon())
    r.scale = 1
    let rep = NSBitmapImageRep(cgImage: r.cgImage!)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

/// Biểu tượng menu bar 18pt: vòng + 6 chấm, chấm trên to hơn. Template -> macOS tự đổi màu theo nền.
func menuBarIcon() -> NSImage {
    let img = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { r in
        NSColor.black.setStroke(); NSColor.black.setFill()
        let ring = NSBezierPath(ovalIn: r.insetBy(dx: 1.5, dy: 1.5)); ring.lineWidth = 1.2; ring.stroke()
        for i in 0..<6 {
            let a = Double(i) * .pi / 3, d: CGFloat = i == 0 ? 4 : 2.6
            let c = CGPoint(x: 9 + 5 * sin(a), y: 9 - 5 * cos(a))
            NSBezierPath(ovalIn: NSRect(x: c.x - d / 2, y: c.y - d / 2, width: d, height: d)).fill()
        }
        return true
    }
    img.isTemplate = true
    return img
}
