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

    static func raise(_ w: AppWindow, appPath: String) {
        if w.minimized { AXUIElementSetAttributeValue(w.element, kAXMinimizedAttribute as CFString, kCFBooleanFalse) }
        AXUIElementSetAttributeValue(w.element, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(w.element, kAXRaiseAction as CFString)
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleURL?.path == appPath }) { bringToFront(app) }
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
