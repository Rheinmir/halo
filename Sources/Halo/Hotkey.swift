import AppKit
import CoreGraphics

/// Bắt phím toàn hệ thống qua CGEventTap (cần quyền Accessibility).
/// Giữ phím kích hoạt một mình -> onShow; thả -> onRelease. Khi vòng đang mở, nuốt các phím điều hướng.
final class Hotkey {
    var isRingOpen: () -> Bool = { false }
    var onShow: () -> Void = {}
    var onRelease: () -> Void = {}
    var onCancel: () -> Void = {}
    var onMouseMove: () -> Void = {}
    var onNavKey: (UInt16, Bool) -> Void = { _, _ in }   // (keyCode, shift)

    /// Phím kích hoạt và độ trễ, lấy từ config (Cài đặt → Chung).
    var trigger: Trigger = .option
    /// Chờ một chút trước khi mở vòng để phím+click, phím+phím khác vẫn dùng bình thường.
    var delay = 0.18

    private var tap: CFMachPort?
    private var optionDown = false
    private var pending: DispatchWorkItem?

    static let navKeys: Set<UInt16> = [48, 36, 76, 53, 49, 123, 124, 125, 126, 18, 19, 20, 21, 23, 22, 26, 28, 25]   // 49 = Space

    func start() -> Bool {
        let mask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.mouseMoved.rawValue) | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
        let me = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                                          eventsOfInterest: mask, callback: { _, type, event, refcon in
            let me = Unmanaged<Hotkey>.fromOpaque(refcon!).takeUnretainedValue()
            return me.handle(type, event)
        }, userInfo: me) else { return false }
        self.tap = tap
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .flagsChanged:
            let f = event.flags
            let others = CGEventFlags([.maskAlternate, .maskCommand, .maskControl, .maskShift, .maskSecondaryFn]).subtracting(trigger.flag)
            let onlyOption = f.contains(trigger.flag) && f.intersection(others).isEmpty
            if onlyOption && !optionDown {
                optionDown = true
                let w = DispatchWorkItem { [weak self] in self?.onShow() }
                pending = w
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: w)
            } else if !f.contains(trigger.flag) && optionDown {
                optionDown = false
                pending?.cancel()
                if isRingOpen() { onRelease() }
            }
        case .keyDown:
            let code = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            if isRingOpen() {
                if Hotkey.navKeys.contains(code) {
                    onNavKey(code, event.flags.contains(.maskShift))
                    return nil   // nuốt phím
                }
                onCancel()
            }
            pending?.cancel()   // ⌥ + phím khác = phím tắt bình thường, không mở vòng
        case .mouseMoved:
            if isRingOpen() { onMouseMove() }
        case .leftMouseDown, .rightMouseDown:
            pending?.cancel()
            if isRingOpen() { onCancel() }
        default: break
        }
        return Unmanaged.passUnretained(event)
    }
}
