import AppKit
import ApplicationServices

/// Cửa sổ của một app, lấy qua Accessibility (đã có quyền, không cần Screen Recording).
/// Chỉ thấy cửa sổ ở Space hiện tại, gồm cả cửa sổ thu nhỏ.
struct AppWindow {
    let title: String
    let element: AXUIElement
    let minimized: Bool
}

enum Windows {
    static func list(for appPath: String) -> [AppWindow] {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleURL?.path == appPath }) else { return [] }
        let ax = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(ax, kAXWindowsAttribute as CFString, &value) == .success,
              let wins = value as? [AXUIElement] else { return [] }
        return wins.compactMap { w in
            guard attr(w, kAXSubroleAttribute) as String? == kAXStandardWindowSubrole as String else { return nil }  // bỏ panel, sheet
            return AppWindow(title: attr(w, kAXTitleAttribute) ?? "", element: w,
                             minimized: attr(w, kAXMinimizedAttribute) ?? false)
        }
        .enumerated().map { i, w in w.title.isEmpty ? AppWindow(title: tr("Window \(i + 1)", "Cửa sổ \(i + 1)"), element: w.element, minimized: w.minimized) : w }
        .prefix(Geometry.maxRows).map { $0 }
    }

    /// Kích hoạt app TRƯỚC rồi mới đưa cửa sổ lên: làm ngược lại thì lúc app được kích hoạt,
    /// macOS đưa cửa sổ chính cũ lên đè (tìm ra khi test bằng cửa sổ thật). Kích hoạt chạy bất đồng bộ,
    /// nên đưa cửa sổ lên thêm một lần sau 0,15 giây.
    static func raise(_ w: AppWindow, appPath: String) {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleURL?.path == appPath }) else { return }
        if w.minimized { AXUIElementSetAttributeValue(w.element, kAXMinimizedAttribute as CFString, kCFBooleanFalse) }
        bringToFront(app)
        let focus = {
            AXUIElementSetAttributeValue(w.element, kAXMainAttribute as CFString, kCFBooleanTrue)
            AXUIElementPerformAction(w.element, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(AXUIElementCreateApplication(app.processIdentifier), kAXFocusedWindowAttribute as CFString, w.element)
        }
        focus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: focus)
    }

    /// Đưa app lên trước. Từ macOS 14, `NSRunningApplication.activate()` gọi từ app chạy nền (như Halo)
    /// thường bị bỏ qua ("cooperative activation"). Đặt AXFrontmost qua Accessibility thì không bị chặn;
    /// không được thì mở lại qua NSWorkspace.
    static func bringToFront(_ app: NSRunningApplication) {
        let ax = AXUIElementCreateApplication(app.processIdentifier)
        if AXUIElementSetAttributeValue(ax, kAXFrontmostAttribute as CFString, kCFBooleanTrue) == .success { return }
        guard let url = app.bundleURL else { app.activate(); return }
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: cfg)
    }

    private static func attr<T>(_ e: AXUIElement, _ name: String) -> T? {
        var v: CFTypeRef?
        return AXUIElementCopyAttributeValue(e, name as CFString, &v) == .success ? v as? T : nil
    }
}
