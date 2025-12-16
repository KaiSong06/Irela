import Foundation

struct StreakState: Codable {
    var currentStreak: Int
    var lastCheckInDate: String?  // YYYY-MM-DD format
    var forgivenessUsedThisMonth: Int
    var lastForgivenessResetMonth: Int  // YYYYMM format
    
    // Was forgiveness used in the current streak?
    var usedForgivenessInCurrentStreak: Bool
    
    static let maxForgivenessPerMonth = 2
    
    init() {
        self.currentStreak = 0
        self.lastCheckInDate = nil
        self.forgivenessUsedThisMonth = 0
        self.lastForgivenessResetMonth = StreakState.currentYearMonth()
        self.usedForgivenessInCurrentStreak = false
    }
    
    static func currentYearMonth() -> Int {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        return (components.year ?? 2024) * 100 + (components.month ?? 1)
    }
    
    var forgivenessRemaining: Int {
        max(0, Self.maxForgivenessPerMonth - forgivenessUsedThisMonth)
    }
}

