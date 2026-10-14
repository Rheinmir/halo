import Foundation

/// Hình học vòng: ô 0 ở đỉnh, xếp theo chiều kim đồng hồ.
enum Geometry {
    static let disc: Double = 292      // đường kính đĩa
    static let radius: Double = 104    // bán kính đặt icon
    static let slot: Double = 60
    static let icon: Double = 44
    static let deadZone: Double = 48   // thả trong vùng này = huỷ

    // Danh sách cửa sổ: đặt THEO HƯỚNG của ô, để rê tiếp ra xa theo hướng đó là vào danh sách
    // mà không cắt qua hình quạt của ô bên cạnh (lỗi tìm ra khi test bằng chuột thật).
    static let listGap: Double = 20
    static let listWidth: Double = 240
    static let rowHeight: Double = 28
    static let headerHeight: Double = 30
    static let maxRows = 8
    static var panelSize: CGSize {
        let listBlock = listGap + headerHeight + Double(maxRows) * rowHeight + 12
        return CGSize(width: disc + 2 * (listGap + listWidth) + 60, height: disc + 2 * listBlock + 40)
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

    static func slotAngle(_ i: Int, count: Int) -> Double { Double(i) * 2 * .pi / Double(count) }

    /// Tâm khối các dòng (so với tâm vòng, y xuống).
    /// Ô ở hai bên -> danh sách ngay ngoài vòng theo hướng ô; ô gần đỉnh/đáy -> danh sách phía trên/dưới vòng.
    static func listCenter(slot i: Int, count: Int, rows: Int) -> CGPoint {
        let a = slotAngle(i, count: count), dx = sin(a), dy = -cos(a)
        let half = Double(rows) * rowHeight / 2, r0 = disc / 2 + listGap
        let limitY = panelSize.height / 2 - headerHeight - 16
        if abs(dx) >= 0.5 {
            let side: Double = dx > 0 ? 1 : -1
            let cy = min(max(dy * r0, -limitY + half), limitY - half)
            return CGPoint(x: dx * r0 + side * listWidth / 2, y: cy)
        }
        let cx = dx * r0
        return dy < 0 ? CGPoint(x: cx, y: -r0 - half)                    // đỉnh: danh sách phía trên, tiêu đề ở trên cùng
                      : CGPoint(x: cx, y: r0 + headerHeight + half)      // đáy: chừa chỗ tiêu đề giữa vòng và danh sách
    }

    /// Tâm hàng k của danh sách (so với tâm vòng, y xuống).
    static func rowCenter(_ k: Int, rows: Int, slot i: Int, count: Int) -> CGPoint {
        let c = listCenter(slot: i, count: count, rows: rows)
        return CGPoint(x: c.x, y: c.y - Double(rows) * rowHeight / 2 + rowHeight * (Double(k) + 0.5))
    }

    /// Đã ra ngoài vòng và vẫn trong khoảng một ô quanh hướng của app -> hàng gần nhất theo y; còn lại -> nil.
    static func rowIndex(dx: Double, dy: Double, rows: Int, slot i: Int, count: Int) -> Int? {
        guard rows >= 2, count > 0, hypot(dx, dy) > disc / 2 else { return nil }
        var a = atan2(dx, -dy); if a < 0 { a += 2 * .pi }
        let d = abs(a - slotAngle(i, count: count)), diff = min(d, 2 * .pi - d)
        guard diff <= 2 * .pi / Double(count) else { return nil }
        let first = rowCenter(0, rows: rows, slot: i, count: count).y
        return min(max(Int(((dy - first) / rowHeight).rounded()), 0), rows - 1)
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
        precondition(abs(p.x - 98.91) < 0.01 && abs(p.y + 32.14) < 0.01, "ô 1/5 trên bán kính 104")
        // danh sách cửa sổ, 4 ô: ô 1 ở bên phải (90°), ô 0 ở đỉnh, 3 hàng
        precondition(listCenter(slot: 1, count: 4, rows: 3).x > disc / 2, "ô bên phải -> danh sách ngoài vòng bên phải")
        precondition(listCenter(slot: 0, count: 4, rows: 3).y < -disc / 2, "ô đỉnh -> danh sách phía trên vòng")
        precondition(listCenter(slot: 2, count: 4, rows: 3).y > disc / 2, "ô đáy -> danh sách phía dưới vòng")
        precondition(rowIndex(dx: 100, dy: 0, rows: 3, slot: 1, count: 4) == nil, "trong vòng -> chưa chọn cửa sổ")
        precondition(rowIndex(dx: -200, dy: 0, rows: 3, slot: 1, count: 4) == nil, "ngược hướng -> nil")
        precondition(rowIndex(dx: 200, dy: 0, rows: 3, slot: 1, count: 4) == 1, "ngang ô -> hàng giữa")
        precondition(rowIndex(dx: 200, dy: -500, rows: 3, slot: 1, count: 4) == 0, "kẹp hàng đầu")
        precondition(rowIndex(dx: 200, dy: 500, rows: 3, slot: 1, count: 4) == 2, "kẹp hàng cuối")
        precondition(rowIndex(dx: 200, dy: 0, rows: 1, slot: 1, count: 4) == nil, "1 cửa sổ -> không bung")
        // đường rê thẳng từ ô ra xa theo hướng ô không đi qua ô khác trước khi ra khỏi vòng (lỗi cũ: ô 4/9 cắt qua ô 3)
        for n in [4, 6, 9, 10] { for i in 0..<n {
            let a = slotAngle(i, count: n)
            for r in stride(from: radius, to: disc / 2, by: 4) {
                precondition(slotIndex(dx: r * sin(a), dy: -r * cos(a), count: n) == i, "rê ra theo hướng ô \(i)/\(n) vẫn ở ô đó")
            }
            precondition(rowIndex(dx: (disc / 2 + 30) * sin(a), dy: -(disc / 2 + 30) * cos(a), rows: 3, slot: i, count: n) != nil,
                         "ra khỏi vòng theo hướng ô \(i)/\(n) -> vào danh sách")
        } }
        print("selftest OK")
    }
}
