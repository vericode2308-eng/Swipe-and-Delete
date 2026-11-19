import Foundation

/// Settings › Appearance (D-25). System follows the iPhone; Light is the Dawn
/// look and Dark is the Dusk look.
public enum AppearanceSetting: String, CaseIterable, Sendable {
    case system, light, dark

    public var title: String {
        switch self { case .system: "System"; case .light: "Light"; case .dark: "Dark" }
    }
}

/// UserDefaults key `settings.appearance` (raw values `system`, `light`, `dark`).
/// Launch with `-settings.appearance dark` to force a look in the simulator.
/// Never rename the key or raw values without a migration.
public struct AppearanceStore: Sendable {
    nonisolated(unsafe) private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func load() -> AppearanceSetting {
        defaults.string(forKey: "settings.appearance").flatMap(AppearanceSetting.init(rawValue:)) ?? .system
    }

    public func save(_ setting: AppearanceSetting) {
        defaults.set(setting.rawValue, forKey: "settings.appearance")
    }
}
