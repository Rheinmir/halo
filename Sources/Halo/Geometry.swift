import Foundation

/// Hình học vòng: ô 0 ở đỉnh, xếp theo chiều kim đồng hồ.
enum Geometry {
    static let disc: Double = 292      // đường kính đĩa
    static let radius: Double = 104    // bán kính đặt icon
    static let slot: Double = 60
    static let icon: Double = 44
    static let deadZone: Double = 48   // thả trong vùng này = huỷ

    // Danh sách cửa sổ bung cạnh vòng
    static let listGap: Double = 16
    static let listWidth: Double = 240
    static let rowHeight: Double = 28
    static let maxRows = 10
    static var panelSize: CGSize {
        CGSize(width: disc + 2 * (listGap + listWidth) + 60, height: max(disc, Double(maxRows) * rowHeight + 100) + 60)
    }

    /// Danh sách nằm bên phải nếu ô ở nửa phải (hoặc đỉnh/đáy), bên trái nếu ô ở nửa trái.
    static func listSide(_ i: Int, count: Int) -> Double { slotOffset(i, count: count).x < -0.5 ? -1 : 1 }

    /// Tâm hàng k của danh sách (so với tâm vòng, y xuống). Danh sách canh giữa theo độ cao của ô, không tràn panel.
    static func rowCenter(_ k: Int, rows: Int, slot i: Int, count: Int) -> CGPoint {
        let side = listSide(i, count: count)
        let half = Double(rows) * rowHeight / 2, limit = panelSize.height / 2 - 64  // chừa chỗ cho tiêu đề danh sách
        let midY = min(max(slotOffset(i, count: count).y, -limit + half), limit - half)
        return CGPoint(x: side * (disc / 2 + listGap + listWidth / 2), y: midY - half + rowHeight * (Double(k) + 0.5))
    }

    /// Chuột đã ra ngoài vòng về phía danh sách -> hàng gần nhất theo y; còn trong vòng hoặc sai phía -> nil.
    static func rowIndex(dx: Double, dy: Double, rows: Int, slot i: Int, count: Int) -> Int? {
        guard rows >= 2, hypot(dx, dy) > disc / 2, dx * listSide(i, count: count) > 0 else { return nil }
        let first = rowCenter(0, rows: rows, slot: i, count: count).y
        return min(max(Int(((dy - first) / rowHeight).rounded()), 0), rows - 1)
    }

    /// dx, dy tính từ tâm vòng, trục y hướng XUỐNG. Trả về ô đang trỏ, nil nếu trong vùng chết.
    static func slotIndex(dx: Double, dy: Double, count: Int) -> Int? {
        guard count > 0, hypot(dx, dy) >= deadZone else { return nil }
        if count == 1 { return 0 }
        var a = atan2(dx, -dy)
        if a < 0 { a += 2 * .pi }
        return Int((a / (2 * .pi / Double(count))).rounded()) % count
    }

    /// Tâm icon của ô i so với tâm vòng, trục y hướng XUỐNG.
    static func slotOffset(_ i: Int, count: Int) -> CGPoint {
        let a = Double(i) * 2 * .pi / Double(count)
        return CGPoint(x: radius * sin(a), y: -radius * cos(a))
    }

    static func selftest() {
        precondition(slotIndex(dx: 0, dy: -10, count: 5) == nil, "vùng chết")
        precondition(slotIndex(dx: 0, dy: -100, count: 5) == 0, "đỉnh = ô 0")
        precondition(slotIndex(dx: 100, dy: 0, count: 4) == 1, "phải = ô 1 khi có 4 ô")
        precondition(slotIndex(dx: 0, dy: 100, count: 4) == 2, "đáy = ô 2")
        precondition(slotIndex(dx: -100, dy: 0, count: 4) == 3, "trái = ô 3")
        precondition(slotIndex(dx: -5, dy: -100, count: 4) == 0, "lệch trái chút vẫn ô 0 (không bị % thành ô cuối sai)")
        precondition(slotIndex(dx: 60, dy: 60, count: 1) == 0)
        let p = slotOffset(1, count: 5)  // ô 1/5 trên bán kính 104
        precondition(abs(p.x - 98.91) < 0.01 && abs(p.y + 32.14) < 0.01, "toạ độ ô khớp bản gốc")
        // danh sách cửa sổ: ô 1/4 (bên phải), 3 hàng
        precondition(listSide(1, count: 4) == 1 && listSide(3, count: 4) == -1 && listSide(0, count: 4) == 1, "phía danh sách")
        precondition(rowIndex(dx: 100, dy: 0, rows: 3, slot: 1, count: 4) == nil, "trong vòng -> chưa chọn cửa sổ")
        precondition(rowIndex(dx: -200, dy: 0, rows: 3, slot: 1, count: 4) == nil, "sai phía -> nil")
        precondition(rowIndex(dx: 200, dy: 0, rows: 3, slot: 1, count: 4) == 1, "ngang ô -> hàng giữa")
        precondition(rowIndex(dx: 200, dy: -500, rows: 3, slot: 1, count: 4) == 0, "kẹp hàng đầu")
        precondition(rowIndex(dx: 200, dy: 500, rows: 3, slot: 1, count: 4) == 2, "kẹp hàng cuối")
        precondition(rowIndex(dx: 200, dy: 0, rows: 1, slot: 1, count: 4) == nil, "1 cửa sổ -> không bung")
        print("selftest OK")
    }
}
