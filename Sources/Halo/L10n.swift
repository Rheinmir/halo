import Foundation

/// Ngôn ngữ giao diện. Mặc định tiếng Anh; `auto` theo macOS (tiếng Việt -> vi, còn lại -> en).
enum Lang: String, Codable, CaseIterable {
    case auto, en, vi
}

enum L10n {
    static var lang: Lang = .en
    static var isVietnamese: Bool {
        switch lang {
        case .vi: return true
        case .en: return false
        case .auto: return Locale.preferredLanguages.first?.hasPrefix("vi") ?? false
        }
    }
}

/// Chuỗi giao diện song ngữ: tr("English", "Tiếng Việt").
/// ponytail: chuỗi nằm ngay trong code, không dùng .strings; đổi sang String Catalog nếu thêm ngôn ngữ thứ ba.
func tr(_ en: String, _ vi: String) -> String { L10n.isVietnamese ? vi : en }
