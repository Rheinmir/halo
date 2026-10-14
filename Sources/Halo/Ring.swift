import AppKit
import SwiftUI

final class RingModel: ObservableObject {
    @Published var apps: [RingApp] = []
    @Published var icons: [NSImage] = []
    @Published var running: Set<String> = []
    @Published var hovered: Int?
    @Published var windows: [AppWindow] = []      // cửa sổ của app đang trỏ (chỉ bung khi >= 2)
    @Published var hoveredWindow: Int?
    @Published var visible = false                // điều khiển hiệu ứng hiện
    var ghost: Int?
    @Published var triggerSymbol = "⌥"
    @Published var previousName: String?
    @Published var lang: Lang = .en             // đổi ngôn ngữ -> vẽ lại vòng          // app dùng trước đó: gợi ý "Space ↩ …" ở tâm vòng                               // Settings: ô đang được kéo tới -> vẽ mờ làm chỗ trống
    var solidBackground = false                   // ảnh preview: NSVisualEffectView không vẽ được offscreen

    var showsWindowList: Bool { hovered != nil && windows.count >= 2 }
}

// MARK: - Vòng đầy đủ (đĩa + danh sách cửa sổ) — nội dung của panel

struct RingView: View {
    @ObservedObject var model: RingModel

    var body: some View {
        ZStack {
            if model.showsWindowList, let h = model.hovered {
                WindowList(model: model, slot: h)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
            DiscView(model: model)
        }
        .frame(width: Geometry.panelSize.width, height: Geometry.panelSize.height)
        .scaleEffect(model.visible ? 1 : 0.92)
        .opacity(model.visible ? 1 : 0)
        .animation(.spring(response: 0.24, dampingFraction: 0.78), value: model.visible)
        .animation(.easeOut(duration: 0.12), value: model.showsWindowList)
    }
}

// MARK: - Đĩa

struct DiscView: View {
    @ObservedObject var model: RingModel
    private let d = Geometry.disc

    var body: some View {
        ZStack {
            Glass(solid: model.solidBackground, shape: Circle())

            // Ô đang trỏ: MỘT tín hiệu — vành khuyên tô phẳng nhạt. Không đĩa, glow hay viền sau icon.
            if let h = model.hovered, model.apps.indices.contains(h) {
                Wedge(index: h, count: model.apps.count, inner: Geometry.deadZone + 14)
                    .fill(Color.accentColor.opacity(0.16))
                    .frame(width: d, height: d)
                .id(h)
                .transition(.opacity)
            }

            ForEach(Array(model.apps.enumerated()), id: \.offset) { i, app in
                Slot(icon: i < model.icons.count ? model.icons[i] : nil,
                     state: model.hovered == nil ? .idle : (model.hovered == i ? .hovered : .dimmed),
                     running: model.running.contains(app.path))
                    .opacity(model.ghost == i ? 0.18 : 1)
                    .offset(x: Geometry.slotOffset(i, count: model.apps.count).x,
                            y: Geometry.slotOffset(i, count: model.apps.count).y)
            }

            CenterLabel(model: model)
        }
        .frame(width: d, height: d)
        .environment(\.colorScheme, .dark)   // kính HUD luôn tối -> chữ, chấm luôn dùng bảng màu tối, kể cả khi hệ thống ở chế độ sáng
        .compositingGroup()
        .shadow(color: .black.opacity(0.38), radius: 28, y: 14)
        .animation(.spring(response: 0.2, dampingFraction: 0.72), value: model.hovered)
    }
}

struct Slot: View {
    enum State { case idle, hovered, dimmed }
    let icon: NSImage?
    let state: State
    let running: Bool

    var body: some View {
        ZStack {
            if let icon {
                Image(nsImage: icon).resizable().interpolation(.high)
                    .frame(width: Geometry.icon, height: Geometry.icon)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            }
            if running {
                Circle().fill(Color.white.opacity(state == .hovered ? 0.95 : 0.6))
                    .frame(width: 4, height: 4)
                    .offset(y: Geometry.slot / 2 - 3)
            }
        }
        .frame(width: Geometry.slot, height: Geometry.slot)
        .scaleEffect(state == .hovered ? 1.14 : 1)
        .opacity(state == .dimmed ? 0.55 : 1)
    }
}

struct CenterLabel: View {
    @ObservedObject var model: RingModel

    var body: some View {
        VStack(spacing: 3) {
            if let h = model.hovered, model.apps.indices.contains(h) {
                Text(model.apps[h].name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2).minimumScaleFactor(0.8)
                Text(subtitle(h))
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                Text(model.triggerSymbol).font(.system(size: 17, weight: .medium)).foregroundStyle(.secondary)
                Text(tr("Point at an app", "Rê tới một app")).font(.system(size: 10.5, weight: .medium)).foregroundStyle(.tertiary)
                if let prev = model.previousName {
                    Text("Space ↩ \(prev)").font(.system(size: 10, weight: .medium)).foregroundStyle(.tertiary)
                        .lineLimit(1).truncationMode(.tail).padding(.top, 2)
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(width: 2 * Geometry.deadZone + 8)
        .foregroundStyle(.primary)
    }

    private func subtitle(_ h: Int) -> String {
        let key = h < 9 ? tr(" · key \(h + 1)", " · phím \(h + 1)") : ""
        if model.windows.count >= 2 { return tr("\(model.windows.count) windows ›", "\(model.windows.count) cửa sổ ›") }
        return (model.running.contains(model.apps[h].path) ? tr("Running", "Đang chạy") : tr("Open", "Mở")) + key
    }
}

// MARK: - Danh sách cửa sổ

struct WindowList: View {
    @ObservedObject var model: RingModel
    let slot: Int

    var body: some View {
        let n = model.apps.count, rows = model.windows.count
        let first = Geometry.rowCenter(0, rows: rows, slot: slot, count: n)
        let mid = Geometry.rowCenter(0, rows: rows, slot: slot, count: n).y + Geometry.rowHeight * Double(rows - 1) / 2
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ForEach(Array(model.windows.enumerated()), id: \.offset) { k, w in
                    WindowRow(window: w, selected: model.hoveredWindow == k)
                }
            }
            .padding(6)
            .background(Glass(solid: model.solidBackground, shape: RoundedRectangle(cornerRadius: 14, style: .continuous)))
            .compositingGroup()
            .shadow(color: .black.opacity(0.32), radius: 20, y: 10)

            // Tiêu đề: icon + tên app, nằm ngay trên khối danh sách
            HStack(spacing: 6) {
                if model.icons.indices.contains(slot) {
                    Image(nsImage: model.icons[slot]).resizable().frame(width: 16, height: 16)
                }
                Text(model.apps[slot].name).font(.system(size: 11.5, weight: .semibold))
                Text(tr("\(rows) windows", "\(rows) cửa sổ")).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
            .offset(y: -26)
        }
        .frame(width: Geometry.listWidth)
        .environment(\.colorScheme, .dark)
        .offset(x: first.x, y: mid)
        .animation(.easeOut(duration: 0.08), value: model.hoveredWindow)
    }
}

struct WindowRow: View {
    let window: AppWindow
    let selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: window.minimized ? "minus.rectangle" : "macwindow")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 16)
                .foregroundStyle(selected ? Color.white : Color.secondary)
            Text(window.title)
                .font(.system(size: 12.5, weight: selected ? .semibold : .regular))
                .lineLimit(1).truncationMode(.middle)
            Spacer(minLength: 4)
            if window.minimized {
                Text(tr("minimized", "thu nhỏ")).font(.system(size: 10)).foregroundStyle(selected ? Color.white.opacity(0.8) : Color.secondary)
            }
        }
        .padding(.horizontal, 9)
        .frame(height: Geometry.rowHeight)
        .foregroundStyle(selected ? Color.white : Color.primary)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(selected ? Color.accentColor : Color.clear))
    }
}

// MARK: - Vật liệu kính

/// Kính mờ sau cửa sổ + vệt sáng phía trên + viền sáng mảnh: cùng ngôn ngữ với HUD của macOS.
struct Glass<S: InsettableShape>: View {
    let solid: Bool
    let shape: S

    var body: some View {
        ZStack {
            if solid { shape.fill(Color(white: 0.16)) } else { VisualEffect().clipShape(shape) }
            shape.fill(LinearGradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.0)],
                                      startPoint: .top, endPoint: .center))
            shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.30), Color.white.opacity(0.06)],
                                              startPoint: .top, endPoint: .bottom), lineWidth: 1)
        }
    }
}

/// Hình quạt của ô i, tâm vòng ở giữa khung; ô 0 ở đỉnh. `inner` > 0 -> vành khuyên (chừa tâm cho chữ).
struct Wedge: Shape {
    let index: Int, count: Int
    var inner: Double = 0
    func path(in r: CGRect) -> Path {
        guard count > 1 else { return Path(ellipseIn: r) }
        let step = 360.0 / Double(count), mid = Double(index) * step - 90
        let a0 = Angle.degrees(mid - step / 2), a1 = Angle.degrees(mid + step / 2)
        let c = CGPoint(x: r.midX, y: r.midY)
        var p = Path()
        p.addArc(center: c, radius: r.width / 2, startAngle: a0, endAngle: a1, clockwise: false)
        if inner > 0 {
            p.addArc(center: c, radius: inner, startAngle: a1, endAngle: a0, clockwise: true)
        } else {
            p.addLine(to: c)
        }
        p.closeSubpath()
        return p
    }
}

struct VisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.appearance = NSAppearance(named: .vibrantDark)   // vòng luôn tối như HUD của macOS
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {}
}

// MARK: - Panel

/// Cửa sổ nổi không viền, không lấy focus — app đang dùng không mất phím gõ.
final class RingPanel: NSPanel {
    private let model: RingModel

    init(model: RingModel) {
        self.model = model
        let size = Geometry.panelSize
        super.init(contentRect: NSRect(origin: .zero, size: size),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false           // bóng do SwiftUI vẽ theo đúng hình tròn
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        ignoresMouseEvents = true
        let host = NSHostingView(rootView: RingView(model: model))
        host.frame = NSRect(origin: .zero, size: size)
        host.autoresizingMask = [.width, .height]
        contentView = host
    }
    override var canBecomeKey: Bool { false }

    /// Đặt tâm panel tại điểm p (toạ độ màn hình Cocoa, y hướng lên).
    func show(centeredAt p: NSPoint) {
        setFrameOrigin(NSPoint(x: p.x - frame.width / 2, y: p.y - frame.height / 2))
        model.visible = false
        orderFrontRegardless()
        DispatchQueue.main.async { self.model.visible = true }
    }

    func hide() {
        model.visible = false
        orderOut(nil)
    }
}
