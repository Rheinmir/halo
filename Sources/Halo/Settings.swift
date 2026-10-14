import AppKit
import ApplicationServices
import SwiftUI
import UniformTypeIdentifiers

/// Nguồn sự thật của Settings: mọi thay đổi ghi file ngay và báo cho vòng nạp lại.
final class SettingsStore: ObservableObject {
    @Published private(set) var config: Config
    @Published var selection: Int?
    @Published var trusted = AXIsProcessTrusted()
    var onChange: (Config) -> Void = { _ in }

    init(config: Config) { self.config = config }

    func update(_ f: (inout Config) -> Void) {
        var c = config
        f(&c)
        c.apps = Array(c.apps.prefix(Config.maxApps))
        guard c != config else { return }
        L10n.lang = c.language   // đặt trước khi publish để lần vẽ lại dùng ngôn ngữ mới
        config = c
        c.save()
        onChange(c)
    }

    /// Thêm app; `at` = vị trí chèn (kéo từ Finder vào giữa hai dòng), nil = cuối danh sách.
    func add(_ urls: [URL], at index: Int? = nil) {
        var at = min(index ?? config.apps.count, config.apps.count)
        update { c in
            for u in urls where u.pathExtension == "app" && !c.apps.contains(where: { $0.path == u.path }) {
                c.apps.insert(RingApp(path: u.path), at: at)
                at += 1
            }
        }
        selection = config.apps.isEmpty ? nil : min(at, config.apps.count) - 1
    }

    /// Kéo thả đổi thứ tự trong danh sách. Giữ lựa chọn đi theo app đang chọn.
    func move(from source: IndexSet, to destination: Int) {
        let picked = selection.map { config.apps[$0].path }
        update { $0.apps.move(fromOffsets: source, toOffset: destination) }
        selection = picked.flatMap { p in config.apps.firstIndex { $0.path == p } }
    }

    func move(_ i: Int, by delta: Int) {
        let j = i + delta
        guard config.apps.indices.contains(i), config.apps.indices.contains(j) else { return }
        update { $0.apps.swapAt(i, j) }
        selection = j
    }

    func remove(_ i: Int) {
        guard config.apps.indices.contains(i) else { return }
        update { $0.apps.remove(at: i) }
        selection = config.apps.isEmpty ? nil : min(i, config.apps.count - 1)
    }

    func pickApps() {
        let p = NSOpenPanel()
        p.allowedContentTypes = [.application]
        p.allowsMultipleSelection = true
        p.directoryURL = URL(fileURLWithPath: "/Applications")
        p.prompt = tr("Add to ring", "Thêm vào vòng")
        if p.runModal() == .OK { add(p.urls) }
    }
}

enum SettingsTab: String, CaseIterable {
    case general = "General", apps = "Apps", about = "About"
    var symbol: String { ["general": "gearshape", "apps": "square.grid.2x2", "about": "info.circle"][rawValue.lowercased()]! }
    var title: String {
        switch self {
        case .general: return tr("General", "Chung")
        case .apps: return tr("Apps", "Ứng dụng")
        case .about: return tr("About", "Giới thiệu")
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @State var tab: SettingsTab = .apps

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { t in
                    Button { tab = t } label: {
                        VStack(spacing: 3) {
                            Image(systemName: t.symbol).font(.system(size: 17, weight: .regular)).frame(height: 20)
                            Text(t.title).font(.system(size: 11))
                        }
                        .frame(width: 78, height: 50)
                        .foregroundStyle(tab == t ? Color.accentColor : Color.secondary)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(tab == t ? Color.primary.opacity(0.07) : Color.clear))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
            Divider()
            Group {
                switch tab {
                case .apps: AppsTab(store: store)
                case .general: GeneralTab(store: store)
                case .about: AboutTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 680, height: 640)
    }
}

// MARK: - Ứng dụng

struct AppsTab: View {
    @ObservedObject var store: SettingsStore
    @State private var dropping = false

    var body: some View {
        HStack(spacing: 0) {
            // Xem trước: vòng thật, thu nhỏ; chọn dòng bên phải thì ô tương ứng sáng lên.
            VStack(spacing: 12) {
                RingEditor(store: store)
                VStack(spacing: 3) {
                    Text(tr("Drag icons on the ring to rearrange", "Kéo icon trên vòng để đổi chỗ")).font(.system(size: 11.5, weight: .medium))
                    Text(tr("Drop apps from Finder onto the ring to add", "Thả app từ Finder vào vòng để thêm")).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 260)
            .frame(maxHeight: .infinity)
            .background(Color.primary.opacity(0.025))

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(tr("Your ring", "Vòng của bạn")).font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("\(store.config.apps.count)/\(Config.maxApps)").font(.system(size: 11.5).monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                // Chọn dòng bằng selection của List (không dùng onTapGesture: nó nuốt mouseDown -> không kéo được).
                List(selection: $store.selection) {
                    ForEach(Array(store.config.apps.enumerated()), id: \.element.path) { i, app in
                        AppRow(index: i, app: app, count: store.config.apps.count,
                               selected: store.selection == i, store: store)
                            .tag(i)
                            .listRowInsets(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .onMove { store.move(from: $0, to: $1) }                       // kéo dòng để đổi vị trí
                    .onInsert(of: [.fileURL]) { at, providers in                   // kéo app từ Finder vào giữa hai dòng
                        load(providers) { store.add($0, at: at) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 44)
                .overlay {
                    if store.config.apps.isEmpty {
                        Text(tr("No apps yet. Click “Add App…” or drag apps here from Finder.", "Chưa có app nào. Bấm “Thêm app…” hoặc kéo app từ Finder vào đây."))
                            .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(30)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.035)))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(dropping ? Color.accentColor : Color.primary.opacity(0.08),
                                  style: StrokeStyle(lineWidth: dropping ? 2 : 1, dash: dropping ? [6, 4] : [])))
                // Danh sách trống: List không có chỗ chèn, nhận thả vào cả khung.
                .onDrop(of: [.fileURL], isTargeted: $dropping) { providers in
                    guard store.config.apps.isEmpty else { return false }
                    load(providers) { store.add($0) }
                    return true
                }

                HStack(spacing: 8) {
                    Button { store.pickApps() } label: { Label(tr("Add App…", "Thêm app…"), systemImage: "plus") }
                        .disabled(store.config.apps.count >= Config.maxApps)
                    // Đọc Dock mỗi lần mở menu: app mới ghim cũng có mặt.
                    Menu {
                        let inRing = Set(store.config.apps.map(\.path))
                        let full = store.config.apps.count >= Config.maxApps
                        ForEach(Config.dockApps(), id: \.path) { app in
                            Button {
                                store.add([URL(fileURLWithPath: app.path)])
                            } label: {
                                Label {
                                    Text(inRing.contains(app.path) ? "\(app.name)  ✓" : app.name)
                                } icon: {
                                    Image(nsImage: menuIcon(app.path))
                                }
                            }
                            .disabled(inRing.contains(app.path) || full)
                        }
                        Divider()
                        Button(tr("Replace with first \(Config.maxApps) Dock apps", "Thay bằng \(Config.maxApps) app đầu Dock")) {
                            store.update { $0.apps = Array(Config.dockApps().prefix(Config.maxApps)) }
                            store.selection = nil
                        }
                    } label: {
                        Text(tr("From Dock", "Từ Dock"))
                    }
                    .fixedSize()
                    Spacer()
                }
                .controlSize(.regular)
            }
            .padding(16)
        }
    }

    private func load(_ providers: [NSItemProvider], _ done: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        var urls: [URL] = []
        for p in providers {
            group.enter()
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                DispatchQueue.main.async { if let url { urls.append(url) }; group.leave() }
            }
        }
        group.notify(queue: .main) { done(urls) }
    }
}

/// Icon 16pt cho mục menu (NSMenu không tự co ảnh lớn).
func menuIcon(_ path: String) -> NSImage {
    let img = NSWorkspace.shared.icon(forFile: path).copy() as! NSImage
    img.size = NSSize(width: 16, height: 16)
    return img
}

struct AppRow: View {
    let index: Int, app: RingApp, count: Int, selected: Bool
    @ObservedObject var store: SettingsStore
    @State private var hover = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(selected ? Color.white.opacity(0.7) : Color.secondary)
                .opacity(hover || selected ? 1 : 0.35)
                .help(tr("Drag to reorder", "Kéo để đổi vị trí"))
            Text("\(index + 1)").font(.system(size: 11, weight: .semibold).monospacedDigit())
                .frame(width: 18, height: 18)
                .background(Circle().fill(selected ? Color.white.opacity(0.25) : Color.primary.opacity(0.08)))
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.path)).resizable().frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(app.name).font(.system(size: 12.5, weight: .medium))
                Text(position).font(.system(size: 10.5)).foregroundStyle(selected ? Color.white.opacity(0.75) : Color.secondary)
            }
            Spacer()
            if hover || selected {
                HStack(spacing: 2) {
                    iconButton("chevron.up", disabled: index == 0) { store.move(index, by: -1) }
                    iconButton("chevron.down", disabled: index == count - 1) { store.move(index, by: 1) }
                    iconButton("minus.circle.fill") { store.remove(index) }
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 42)
        .foregroundStyle(selected ? Color.white : Color.primary)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(selected ? Color.accentColor : (hover ? Color.primary.opacity(0.05) : Color.clear)))
        .contentShape(Rectangle())
        .onHover { hover = $0 }
    }

    /// Vị trí trên vòng, theo giờ đồng hồ: ô 0 = 12 giờ.
    private var position: String {
        let hour = Int((Double(index) / Double(max(count, 1)) * 12).rounded()) % 12
        return tr("At \(hour == 0 ? 12 : hour) o’clock", "Vị trí \(hour == 0 ? 12 : hour) giờ")
    }

    private func iconButton(_ name: String, disabled: Bool = false, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name).font(.system(size: 12, weight: .semibold)).frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.3 : 0.9)
        .disabled(disabled)
    }
}

// MARK: - Sửa trực tiếp trên vòng

/// Vòng xem trước có thể kéo: nắm icon kéo sang ô khác để đổi chỗ, thả app từ Finder vào ô để chèn, bấm để chọn.
struct RingEditor: View {
    @ObservedObject var store: SettingsStore
    @State private var dragFrom: Int?
    @State private var dragTarget: Int?
    @State private var dragPoint: CGPoint = .zero
    @State private var dropTarget: Int?            // kéo từ Finder: ô sẽ chèn vào (trên vòng n+1 ô)

    static let scale = 0.72
    static let side: CGFloat = 220
    private var center: CGPoint { CGPoint(x: Self.side / 2, y: Self.side / 2) }

    var body: some View {
        let apps = store.config.apps
        ZStack {
            DiscView(model: model(apps)).scaleEffect(Self.scale)
            if let from = dragFrom, apps.indices.contains(from) {
                // icon đang được nắm, đi theo con trỏ
                Image(nsImage: NSWorkspace.shared.icon(forFile: apps[from].path)).resizable()
                    .frame(width: Geometry.icon * Self.scale * 1.2, height: Geometry.icon * Self.scale * 1.2)
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 5)
                    .position(dragPoint)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: Self.side, height: Self.side)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0).onChanged(changed).onEnded(ended))
        .onDrop(of: [.fileURL], delegate: FinderDrop(editor: self))
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: dragTarget)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: dropTarget)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: store.config.apps)
    }

    /// Ô dưới điểm p của khung editor, trên vòng `count` ô.
    func slot(at p: CGPoint, count: Int) -> Int? {
        Geometry.slotIndex(dx: (p.x - center.x) / Self.scale, dy: (p.y - center.y) / Self.scale, count: count)
    }

    /// Mô hình vẽ: thứ tự đã "dời thử" theo thao tác kéo, ô đích vẽ mờ làm chỗ trống.
    private func model(_ apps: [RingApp]) -> RingModel {
        var shown = apps
        var ghost: Int?
        if let from = dragFrom, let to = dragTarget, apps.indices.contains(from) {
            shown.insert(shown.remove(at: from), at: to)
            ghost = to
        } else if let at = dropTarget {
            shown.insert(RingApp(path: "/System/Library/CoreServices/Finder.app"), at: min(at, shown.count))
            ghost = at
        }
        let m = RingModel()
        m.apps = shown
        m.icons = shown.map { NSWorkspace.shared.icon(forFile: $0.path) }
        m.hovered = ghost ?? (dragFrom == nil ? store.selection : nil)
        m.ghost = ghost
        m.visible = true
        m.solidBackground = true
        return m
    }

    private func changed(_ v: DragGesture.Value) {
        let n = store.config.apps.count
        if dragFrom == nil {
            guard hypot(v.translation.width, v.translation.height) > 4,
                  let i = slot(at: v.startLocation, count: n) else { return }
            dragFrom = i
        }
        dragPoint = v.location
        dragTarget = slot(at: v.location, count: n) ?? dragFrom
    }

    private func ended(_ v: DragGesture.Value) {
        defer { dragFrom = nil; dragTarget = nil }
        guard let from = dragFrom else {                       // không kéo = bấm chọn ô
            store.selection = slot(at: v.location, count: store.config.apps.count)
            return
        }
        guard let to = dragTarget, to != from else { return }
        store.move(from: IndexSet(integer: from), to: to > from ? to + 1 : to)
        store.selection = to
    }

    struct FinderDrop: DropDelegate {
        let editor: RingEditor
        private var n: Int { editor.store.config.apps.count }

        func validateDrop(info: DropInfo) -> Bool { info.hasItemsConforming(to: [.fileURL]) && n < Config.maxApps }
        func dropUpdated(info: DropInfo) -> DropProposal? {
            editor.dropTarget = editor.slot(at: info.location, count: n + 1) ?? n
            return DropProposal(operation: .copy)
        }
        func dropExited(info: DropInfo) { editor.dropTarget = nil }
        func performDrop(info: DropInfo) -> Bool {
            let at = editor.slot(at: info.location, count: n + 1) ?? n
            editor.dropTarget = nil
            let store = editor.store
            for p in info.itemProviders(for: [.fileURL]) {
                _ = p.loadObject(ofClass: URL.self) { url, _ in
                    if let url { DispatchQueue.main.async { store.add([url], at: at) } }
                }
            }
            return true
        }
    }
}

// MARK: - Chung

struct GeneralTab: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            section(tr("Trigger", "Phím kích hoạt")) {
                row(tr("Open the ring with", "Mở vòng bằng"), detail: store.config.trigger == .fn
                    ? tr("Set “Press 🌐 key to” to “Do Nothing” in System Settings → Keyboard so it doesn’t open the emoji picker",
                         "Nên tắt “Press 🌐 key to” trong System Settings → Keyboard để phím không mở bảng emoji")
                    : tr("Hold this key on its own. Key + click and key + other keys still work as usual",
                         "Giữ một mình phím này. Phím + click hay phím + phím khác vẫn chạy bình thường")) {
                    Picker("", selection: Binding(get: { store.config.trigger }, set: { v in store.update { $0.trigger = v } })) {
                        ForEach(Trigger.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .labelsHidden().fixedSize()
                }
                Divider()
                row(tr("Delay", "Độ trễ"), detail: tr("How long to hold before the ring appears",
                                                   "Giữ bao lâu thì vòng hiện")) {
                    HStack(spacing: 10) {
                        Slider(value: Binding(get: { store.config.delay }, set: { v in store.update { $0.delay = (v * 100).rounded() / 100 } }),
                               in: 0...0.5)
                            .frame(width: 160)
                        Text(String(format: tr("%.2f s", "%.2f giây"), store.config.delay))
                            .font(.system(size: 11.5).monospacedDigit()).foregroundStyle(.secondary).frame(width: 62, alignment: .trailing)
                    }
                }
            }
            section(tr("Ring", "Vòng")) {
                row(tr("Show at", "Hiện ở"), detail: nil) {
                    Picker("", selection: Binding(get: { store.config.position }, set: { v in store.update { $0.position = v } })) {
                        Text(tr("Screen center", "Giữa màn hình")).tag("center")
                        Text(tr("Pointer", "Tại con trỏ")).tag("cursor")
                    }
                    .pickerStyle(.segmented).frame(width: 220).labelsHidden()
                }
                Divider()
                row(tr("Window list", "Danh sách cửa sổ"), detail: tr("For apps with 2+ windows: move past the ring’s edge to pick one",
                                                                     "App có từ 2 cửa sổ: rê ra ngoài vòng để chọn cửa sổ")) {
                    Toggle("", isOn: Binding(get: { store.config.windows }, set: { v in store.update { $0.windows = v } }))
                        .toggleStyle(.switch).labelsHidden()
                }
                Divider()
                row(tr("Tick sound when switching apps", "Tiếng tick khi đổi app"), detail: nil) {
                    Toggle("", isOn: Binding(get: { store.config.tick }, set: { v in store.update { $0.tick = v } }))
                        .toggleStyle(.switch).labelsHidden()
                }
            }
            section(tr("Language", "Ngôn ngữ")) {
                row(tr("Interface language", "Ngôn ngữ giao diện"), detail: nil) {
                    Picker("", selection: Binding(get: { store.config.language }, set: { v in store.update { $0.language = v } })) {
                        Text(tr("Follow macOS", "Theo macOS")).tag(Lang.auto)
                        Text("English").tag(Lang.en)
                        Text("Tiếng Việt").tag(Lang.vi)
                    }
                    .labelsHidden().fixedSize()
                }
            }
            section(tr("Permission", "Quyền")) {
                row("Accessibility", detail: store.trusted
                    ? tr("Granted. Halo can read the trigger key and windows.", "Đã cấp. Halo đọc được phím kích hoạt và cửa sổ.")
                    : tr("Not granted. The ring won’t appear.", "Chưa cấp. Vòng sẽ không hiện.")) {
                    if store.trusted {
                        Label(tr("Enabled", "Đã bật"), systemImage: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 12, weight: .medium))
                    } else {
                        Button(tr("Open Settings…", "Mở cài đặt…")) {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(24)
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(.secondary)
            VStack(spacing: 10) { content() }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.035)))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.primary.opacity(0.07)))
        }
    }

    private func row<C: View>(_ title: String, detail: String?, @ViewBuilder _ trailing: () -> C) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12.5))
                if let detail { Text(detail).font(.system(size: 11)).foregroundStyle(.secondary) }
            }
            Spacer()
            trailing()
        }
    }
}

// MARK: - Giới thiệu

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 10) {
            AppIcon().frame(width: 1024, height: 1024).scaleEffect(96.0 / 1024).frame(width: 96, height: 96)
            Text("Halo").font(.system(size: 20, weight: .semibold))
            Text(tr("Version 0.3.0", "Phiên bản 0.3.0")).font(.system(size: 12)).foregroundStyle(.secondary)
            Text(tr("Your favorite apps, one gesture away.\nInspired by FowyRing from Fowl Labs.",
                    "Ứng dụng yêu thích của bạn, trong một cử chỉ.\nLấy cảm hứng từ FowyRing của Fowl Labs."))
                .font(.system(size: 12)).multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.top, 4)
            HStack(spacing: 10) {
                Button(tr("Show Config File", "Mở file cấu hình")) { NSWorkspace.shared.activateFileViewerSelecting([Config.url]) }
                Button(tr("View FowyRing", "Xem FowyRing")) { NSWorkspace.shared.open(URL(string: "https://fowllabs.com/apps/fowyring/")!) }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Cửa sổ

/// Khi cửa sổ Cài đặt mở, Halo hiện trong Dock và ⌘Tab để dễ tìm; đóng thì về lại chỉ menu bar.
final class SettingsWindow: NSWindow, NSWindowDelegate {
    init(store: SettingsStore) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 680, height: 640),
                   styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        title = "Halo"
        isReleasedWhenClosed = false
        contentView = NSHostingView(rootView: SettingsView(store: store))
        delegate = self
        center()
    }

    func present() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
