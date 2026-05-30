import Foundation

/// Persists user-chosen shortcuts in `UserDefaults`.
///
/// Per-display bindings are keyed by a stable display UUID (see
/// `DisplayManager.stableKey`) so they survive reconnects and reordering.
/// A missing binding means "use the positional default" (see `Shortcuts`).
final class HotKeyStore {
    static let shared = HotKeyStore()

    private let defaults = UserDefaults.standard
    private let perDisplayKey = "perDisplayBindings.v1"
    private let nextKey = "nextBinding.v1"
    private let prevKey = "prevBinding.v1"

    // MARK: - Per-display bindings

    private func perDisplayMap() -> [String: KeyCombo] {
        guard let data = defaults.data(forKey: perDisplayKey),
              let map = try? JSONDecoder().decode([String: KeyCombo].self, from: data) else { return [:] }
        return map
    }

    func binding(forDisplay key: String) -> KeyCombo? { perDisplayMap()[key] }

    func setBinding(_ combo: KeyCombo?, forDisplay key: String) {
        var map = perDisplayMap()
        map[key] = combo                                // nil removes → reverts to default
        if let data = try? JSONEncoder().encode(map) { defaults.set(data, forKey: perDisplayKey) }
    }

    // MARK: - Cycle bindings

    private func combo(forKey key: String) -> KeyCombo? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(KeyCombo.self, from: data)
    }

    private func setCombo(_ combo: KeyCombo?, forKey key: String) {
        if let combo, let data = try? JSONEncoder().encode(combo) { defaults.set(data, forKey: key) }
        else { defaults.removeObject(forKey: key) }
    }

    func nextBinding() -> KeyCombo? { combo(forKey: nextKey) }
    func prevBinding() -> KeyCombo? { combo(forKey: prevKey) }
    func setNext(_ combo: KeyCombo?) { setCombo(combo, forKey: nextKey) }
    func setPrev(_ combo: KeyCombo?) { setCombo(combo, forKey: prevKey) }

    // MARK: - Reset

    func resetAll() {
        defaults.removeObject(forKey: perDisplayKey)
        defaults.removeObject(forKey: nextKey)
        defaults.removeObject(forKey: prevKey)
    }
}
