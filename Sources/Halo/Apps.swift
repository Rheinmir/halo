import AppKit

/// Phím bổ trợ giữ một mình để mở vòng.
enum Trigger: String, Codable, CaseIterable {
    case option, control, command, fn

    var flag: CGEventFlags {
        switch self {
        case .option: return .maskAlternate
        case .control: return .maskControl
        case .command: return .maskCommand
        case .fn: return .maskSecondaryFn
        }
    }
    var symbol: String { ["option": "⌥", "control": "⌃", "command": "⌘", "fn": "🌐"][rawValue]! }
    var label: String { ["option": "⌥ Option", "control": "⌃ Control", "command": "⌘ Command", "fn": "🌐 Globe (fn)"][rawValue]! }
}

struct RingApp: Codable, Equatable {
    var path: String
    var name: String { FileManager.default.displayName(atPath: path).replacingOccurrences(of: ".app", with: "") }
}

/// Danh sách app lưu ở ~/Library/Application Support/Halo/config.json.
/// Lần đầu: lấy tối đa 8 app ghim trên Dock.
struct Config: Codable, Equatable {
    var apps: [RingApp]
    var position: String = "center"   // "center" | "cursor"
    var tick: Bool = true
    var windows: Bool = true          // bung danh sách cửa sổ khi app có từ 2 cửa sổ
    var trigger: Trigger = .option    // phím giữ để mở vòng
    var delay: Double = 0.18          // giữ bao lâu thì vòng hiện (giây)

    init(apps: [RingApp]) { self.apps = apps }

    /// Đọc khoan dung: file cũ thiếu mục mới vẫn đọc được, không bị ghi đè bằng mặc định.
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        apps = try c.decodeIfPresent([RingApp].self, forKey: .apps) ?? []
        position = try c.decodeIfPresent(String.self, forKey: .position) ?? "center"
        tick = try c.decodeIfPresent(Bool.self, forKey: .tick) ?? true
        windows = try c.decodeIfPresent(Bool.self, forKey: .windows) ?? true
        trigger = (try? c.decodeIfPresent(Trigger.self, forKey: .trigger)) ?? .option
        delay = min(max(try c.decodeIfPresent(Double.self, forKey: .delay) ?? 0.18, 0), 0.5)
    }

    static let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Halo", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }()

    static func load() -> Config {
        if let data = try? Data(contentsOf: url), let c = try? JSONDecoder().decode(Config.self, from: data) {
            var c = c
            c.apps = Array(c.apps.filter { FileManager.default.fileExists(atPath: $0.path) }.prefix(Config.maxApps))
            return c
        }
        let c = Config(apps: defaultApps())
        c.save()
        return c
    }

    func save() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        try? enc.encode(self).write(to: Config.url)
    }

    static let maxApps = 10

    /// Mọi app ĐƯỢC GHIM trên Dock (không gồm mục "gần đây"), đúng thứ tự, bỏ app không còn tồn tại.
    static func dockApps() -> [RingApp] {
        let items = UserDefaults(suiteName: "com.apple.dock")?.array(forKey: "persistent-apps") as? [[String: Any]] ?? []
        let paths = items.compactMap { item -> String? in
            guard let tile = item["tile-data"] as? [String: Any],
                  let file = tile["file-data"] as? [String: Any],
                  let s = file["_CFURLString"] as? String else { return nil }
            return URL(string: s)?.path ?? s
        }
        return paths.filter { FileManager.default.fileExists(atPath: $0) }.map { RingApp(path: $0) }
    }

    /// Lần đầu chạy: 8 app ghim đầu Dock, Dock trống thì dùng vài app hệ thống.
    static func defaultApps() -> [RingApp] {
        let dock = dockApps()
        let fallback = ["/System/Library/CoreServices/Finder.app", "/Applications/Safari.app",
                        "/System/Applications/Mail.app", "/System/Applications/Notes.app"].map { RingApp(path: $0) }
        return Array((dock.isEmpty ? fallback : dock).prefix(8))
    }
}
