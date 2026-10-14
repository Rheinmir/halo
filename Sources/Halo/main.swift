import AppKit
import ApplicationServices
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = RingModel()
    private lazy var panel = RingPanel(model: model)
    private let hotkey = Hotkey()
    private var status: NSStatusItem!
    private var config = Config.load()
    private lazy var store = SettingsStore(config: config)
    private lazy var settings = SettingsWindow(store: store)
    private var center = NSPoint.zero   // tâm vòng trên màn hình (Cocoa, y lên)
    private var open = false
    private var retry: Timer?
    /// Hai app được kích hoạt gần nhất (không tính Halo): Space trên vòng quay về `previousApp`.
    private var currentApp: NSRunningApplication? = NSWorkspace.shared.frontmostApplication
    private var previousApp: NSRunningApplication?

    /// Bấm icon Halo trên Dock (khi đang hiện) -> mở lại Cài đặt.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        openSettings()
        return true
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = menuBarIcon()
        status.button?.toolTip = "Halo"
        store.onChange = { [unowned self] c in config = c; apply() }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil, queue: .main) { [unowned self] n in
            guard let app = n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
                  app.processIdentifier != currentApp?.processIdentifier else { return }
            previousApp = currentApp
            currentApp = app
        }
        apply()
        wire()
        startTap()
    }

    // MARK: menu bar

    private func buildMenu(trusted: Bool) {
        let m = NSMenu()
        if !trusted {
            m.addItem(withTitle: tr("Grant Accessibility access…", "Cấp quyền Accessibility…"), action: #selector(openAX), keyEquivalent: "").target = self
            m.addItem(.separator())
        }
        m.addItem(withTitle: tr("Hold \(config.trigger.symbol) to open the ring · \(config.apps.count) apps", "Giữ \(config.trigger.symbol) để mở vòng · \(config.apps.count) app"), action: nil, keyEquivalent: "")
        m.addItem(withTitle: tr("Settings…", "Cài đặt…"), action: #selector(openSettings), keyEquivalent: ",").target = self
        m.addItem(.separator())
        m.addItem(withTitle: tr("Quit Halo", "Thoát Halo"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        status.menu = m
    }

    @objc private func openAX() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    @objc private func openSettings() {
        store.trusted = AXIsProcessTrusted()
        settings.present()
    }

    private func apply() {
        L10n.lang = config.language
        model.lang = config.language
        model.apps = config.apps
        model.icons = config.apps.map { NSWorkspace.shared.icon(forFile: $0.path) }
        model.triggerSymbol = config.trigger.symbol
        hotkey.trigger = config.trigger
        hotkey.delay = config.delay
        buildMenu(trusted: AXIsProcessTrusted())
    }

    // MARK: quyền + event tap

    private func startTap() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(opts), hotkey.start() {
            granted()
            return
        }
        buildMenu(trusted: false)
        settings.present()   // lần đầu: mở Settings để người dùng thấy app và nút cấp quyền
        // Người dùng bật quyền trong System Settings -> tự thử lại, không cần mở lại app.
        retry = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] t in
            guard let self, AXIsProcessTrusted(), self.hotkey.start() else { return }
            t.invalidate()
            self.granted()
        }
    }

    private func granted() {
        buildMenu(trusted: true)
        store.trusted = true
    }

    // MARK: vòng

    private func wire() {
        hotkey.isRingOpen = { [unowned self] in open }
        hotkey.onShow = { [unowned self] in show() }
        hotkey.onRelease = { [unowned self] in commit() }
        hotkey.onCancel = { [unowned self] in hide() }
        hotkey.onMouseMove = { [unowned self] in track() }
        hotkey.onNavKey = { [unowned self] code, shift in nav(code, shift) }
    }

    private func show() {
        guard !open, !model.apps.isEmpty else { return }
        let mouse = NSEvent.mouseLocation
        if config.position == "cursor" {
            center = mouse
        } else {
            let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main!
            center = NSPoint(x: screen.frame.midX, y: screen.frame.midY)
        }
        let runningPaths = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleURL?.path })
        model.running = Set(model.apps.map(\.path).filter(runningPaths.contains))
        model.hovered = nil
        model.windows = []
        model.hoveredWindow = nil
        model.previousName = previousApp.flatMap { $0.isTerminated ? nil : $0.localizedName }
        open = true
        panel.show(centeredAt: center)
        track()
    }

    private func track() {
        let m = NSEvent.mouseLocation
        let dx = m.x - center.x, dy = -(m.y - center.y), n = model.apps.count
        // Đang có danh sách cửa sổ và chuột đã ra ngoài vòng về phía đó -> chọn cửa sổ, giữ nguyên app.
        if let h = model.hovered, model.showsWindowList,
           let row = Geometry.rowIndex(dx: dx, dy: dy, rows: model.windows.count, slot: h, count: n) {
            if row != model.hoveredWindow { model.hoveredWindow = row; tick() }
            return
        }
        model.hoveredWindow = nil
        setHovered(Geometry.slotIndex(dx: dx, dy: dy, count: n))
    }

    private func setHovered(_ i: Int?) {
        guard i != model.hovered else { return }
        model.hovered = i
        model.hoveredWindow = nil
        model.windows = (i != nil && config.windows && model.running.contains(model.apps[i!].path))
            ? Windows.list(for: model.apps[i!].path) : []
        if i != nil { tick() }
    }

    private func tick() {
        if config.tick { NSSound(named: "Tink")?.play() }
    }

    private func nav(_ code: UInt16, _ shift: Bool) {
        let n = model.apps.count
        let digits: [UInt16: Int] = [18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8]
        switch code {
        case 53: hide()                                         // Esc
        case 49:                                                // Space: đóng vòng, về ngay app dùng trước đó
            hide()
            if let prev = previousApp, !prev.isTerminated { Windows.bringToFront(prev) }
        case 36, 76: commit()                                   // Enter
        case 48: setHovered((((model.hovered ?? (shift ? 0 : -1)) + (shift ? -1 : 1)) % n + n) % n)   // Tab / ⇧Tab
        case 126 where model.showsWindowList && model.hoveredWindow != nil:                      // ↑ trong danh sách cửa sổ
            model.hoveredWindow = max(0, model.hoveredWindow! - 1)
        case 125 where model.showsWindowList:                                                     // ↓ vào / trong danh sách
            model.hoveredWindow = min(model.windows.count - 1, (model.hoveredWindow ?? -1) + 1)
        case 126: setHovered(Geometry.slotIndex(dx: 0, dy: -Geometry.deadZone, count: n))   // ↑
        case 124: setHovered(Geometry.slotIndex(dx: Geometry.deadZone, dy: 0, count: n))    // →
        case 125: setHovered(Geometry.slotIndex(dx: 0, dy: Geometry.deadZone, count: n))    // ↓
        case 123: setHovered(Geometry.slotIndex(dx: -Geometry.deadZone, dy: 0, count: n))   // ←
        default:
            if let d = digits[code], d < n { model.hovered = d; model.hoveredWindow = nil; commit() }
        }
    }

    private func commit() {
        let app = model.hovered.flatMap { model.apps.indices.contains($0) ? model.apps[$0] : nil }
        let win = model.hoveredWindow.flatMap { model.windows.indices.contains($0) ? model.windows[$0] : nil }
        hide()
        guard let app else { return }
        if let win { return Windows.raise(win, appPath: app.path) }
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleURL?.path == app.path }) {
            return Windows.bringToFront(running)
        }
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: app.path), configuration: cfg)
    }

    private func hide() {
        guard open else { return }
        open = false
        model.hovered = nil
        model.windows = []
        model.hoveredWindow = nil
        panel.hide()
    }
}

// MARK: - Công cụ dòng lệnh (kiểm thử, xuất ảnh)

/// Vẽ view bằng chính AppKit (offscreen) để control thật như Toggle/Picker hiện đúng.
@MainActor func snapshot<V: View>(_ view: V, size: CGSize, to path: String, dark: Bool = true) {
    let host = NSHostingView(rootView: view.environment(\.colorScheme, dark ? .dark : .light))
    host.frame = NSRect(origin: .zero, size: size)
    host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    let win = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
    win.contentView = host
    host.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.4))   // cho animation/layout xong
    let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
    host.cacheDisplay(in: host.bounds, to: rep)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

let args = CommandLine.arguments
func arg(_ flag: String) -> [String]? {
    guard let i = args.firstIndex(of: flag) else { return nil }
    return Array(args[(i + 1)...])
}

// --lang en|vi: ngôn ngữ cho ảnh xuất ra (mặc định theo config)
if let a = arg("--lang"), let l = a.first.flatMap(Lang.init(rawValue:)) { L10n.lang = l } else { L10n.lang = Config.load().language }

if args.contains("--selftest") {
    Geometry.selftest()
    exit(0)
}
if let a = arg("--icon"), let out = a.first {
    MainActor.assumeIsolated { writeIcon(to: out) }
    exit(0)
}
// --preview out.png [ô] [ô-cửa-sổ cửa-sổ-1 cửa-sổ-2 …]: ảnh vòng, có thể kèm danh sách cửa sổ giả.
if let a = arg("--preview"), let out = a.first {
    MainActor.assumeIsolated {
        _ = NSApplication.shared
        let model = RingModel()
        model.solidBackground = true
        model.apps = Config.load().apps
        model.icons = model.apps.map { NSWorkspace.shared.icon(forFile: $0.path) }
        model.running = Set(model.apps.prefix(4).map(\.path))
        model.hovered = a.count > 1 ? Int(a[1]).flatMap { model.apps.indices.contains($0) ? $0 : nil } : nil
        if a.count > 3 {
            model.hoveredWindow = Int(a[2])
            model.windows = a[3...].map { AppWindow(title: $0.hasPrefix("~") ? String($0.dropFirst()) : $0, element: AXUIElementCreateSystemWide(), minimized: $0.hasPrefix("~")) }
        }
        model.previousName = "Vivaldi"
        model.visible = true
        let bg = ZStack {
            LinearGradient(colors: [Color(red: 0.16, green: 0.20, blue: 0.32), Color(red: 0.08, green: 0.09, blue: 0.14)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RingView(model: model)
        }
        snapshot(bg, size: Geometry.panelSize, to: out)
    }
    exit(0)
}
// --preview-settings out.png [general|apps|about] [light]
if let a = arg("--preview-settings"), let out = a.first {
    MainActor.assumeIsolated {
        _ = NSApplication.shared
        var c = Config.load()
        if let a = arg("--lang"), let l = a.first.flatMap(Lang.init(rawValue:)) { c.language = l }   // chỉ trong ảnh, không ghi file
        let store = SettingsStore(config: c)
        store.selection = 1
        let tab = SettingsTab.allCases.first { $0.rawValue.lowercased() == (a.count > 1 ? a[1] : "apps") } ?? .apps
        snapshot(SettingsView(store: store, tab: tab).background(Color(nsColor: .windowBackgroundColor)),
                 size: CGSize(width: 680, height: 640), to: out, dark: !a.contains("light"))
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
