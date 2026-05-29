import AppKit
import CoreGraphics

/// Enumerates the active displays and warps the mouse cursor between them.
///
/// Cursor movement uses `CGWarpMouseCursorPosition`, which — unlike posting
/// synthetic `CGEvent`s — does **not** require Accessibility permission.
/// All coordinates are in the global display space (top-left origin, points),
/// which is the space shared by `CGDisplayBounds`, `CGWarpMouseCursorPosition`
/// and `CGEvent.location`.
final class DisplayManager {

    /// Active displays ordered left → right (then top → bottom) so that display
    /// numbering and next/previous cycling are stable and intuitive.
    func orderedDisplays() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }
        return Array(ids.prefix(Int(count))).sorted {
            let a = CGDisplayBounds($0), b = CGDisplayBounds($1)
            return a.minX != b.minX ? a.minX < b.minX : a.minY < b.minY
        }
    }

    /// Centre point of a display in global coordinates.
    func center(of id: CGDirectDisplayID) -> CGPoint {
        let b = CGDisplayBounds(id)
        return CGPoint(x: b.midX, y: b.midY)
    }

    /// Warp the cursor to the centre of the given display.
    func moveCursor(to id: CGDirectDisplayID) {
        CGWarpMouseCursorPosition(center(of: id))
        // Re-associate so the next physical mouse movement continues smoothly
        // from the warped position rather than snapping back. (boolean_t == Int32)
        CGAssociateMouseAndMouseCursorPosition(1)
    }

    /// The display currently containing the cursor (falls back to the main display).
    func currentDisplay() -> CGDirectDisplayID {
        let point = CGEvent(source: nil)?.location ?? .zero
        let ids = orderedDisplays()
        return ids.first(where: { CGDisplayBounds($0).contains(point) }) ?? CGMainDisplayID()
    }

    /// Move the cursor to the next (or previous) display, wrapping around.
    func moveToAdjacentDisplay(forward: Bool) {
        let ids = orderedDisplays()
        guard ids.count > 1 else {
            if let only = ids.first { moveCursor(to: only) }
            return
        }
        let index = ids.firstIndex(of: currentDisplay()) ?? 0
        let step = forward ? 1 : -1
        let next = ((index + step) % ids.count + ids.count) % ids.count
        moveCursor(to: ids[next])
    }
}
