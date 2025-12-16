import Foundation

/// Depth level determines how much insight the app surfaces
/// Does NOT affect daily check-in — only output/recaps
enum DepthLevel: Int, CaseIterable, Codable {
    case light = 1   // Default: basics only
    case reflect = 2 // Pattern callouts
    case deep = 3    // Richer narratives
    
    var title: String {
        switch self {
        case .light:   return "Light"
        case .reflect: return "Reflect"
        case .deep:    return "Deep"
        }
    }
    
    var description: String {
        switch self {
        case .light:   return "One tap, once a day"
        case .reflect: return "More patterns, still gentle"
        case .deep:    return "Richer summaries and longer reflections"
        }
    }
}

/// User preferences stored locally
struct UserSettings: Codable {
    var depthLevel: DepthLevel
    
    static let `default` = UserSettings(depthLevel: .light)
}

/// Simple settings storage
final class SettingsService {
    static let shared = SettingsService()
    private let key = "user_settings"
    
    private init() {}
    
    func load() -> UserSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    func save(_ settings: UserSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    var depthLevel: DepthLevel {
        get { load().depthLevel }
        set {
            var settings = load()
            settings.depthLevel = newValue
            save(settings)
        }
    }
}

