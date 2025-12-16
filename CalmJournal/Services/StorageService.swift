import Foundation

// Offline-first local storage with cloud sync
// One entry per day max
final class StorageService {
    static let shared = StorageService()
    private let key = "journal_entries"
    private let streakKey = "streak_state"
    
    private init() {}
    
    // MARK: - Entry Storage
    
    func save(_ entry: Entry) {
        var entries = loadAll()
        // Remove existing entry for same date (one per day)
        entries.removeAll { $0.date == entry.date }
        entries.append(entry)
        
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
        
        // Update streak after saving entry
        updateStreakOnCheckIn(for: entry.date)
        
        // Sync to cloud (fire and forget)
        Task {
            await SupabaseService.shared.uploadEntry(entry)
        }
    }
    
    func loadAll() -> [Entry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
    
    func todaysEntry() -> Entry? {
        let today = Entry.todayString()
        return loadAll().first { $0.date == today }
    }
    
    func lastSevenDays() -> [Entry] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoff = formatter.string(from: sevenDaysAgo)
        
        return loadAll().filter { $0.date >= cutoff }
    }
    
    func hasSevenDaysOfData() -> Bool {
        lastSevenDays().count >= 7
    }
    
    // MARK: - Cloud Sync
    
    /// Sync local entries with cloud (call on app launch)
    func syncWithCloud() async {
        let localEntries = loadAll()
        let mergedEntries = await SupabaseService.shared.syncAll(localEntries: localEntries)
        
        // Save merged entries locally
        if let data = try? JSONEncoder().encode(mergedEntries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // MARK: - Streak Storage
    
    func loadStreakState() -> StreakState {
        guard let data = UserDefaults.standard.data(forKey: streakKey),
              var state = try? JSONDecoder().decode(StreakState.self, from: data) else {
            return StreakState()
        }
        
        // Reset forgiveness if new month (runs silently on load)
        let currentMonth = StreakState.currentYearMonth()
        if state.lastForgivenessResetMonth != currentMonth {
            state.forgivenessUsedThisMonth = 0
            state.lastForgivenessResetMonth = currentMonth
            saveStreakState(state)
        }
        
        return state
    }
    
    private func saveStreakState(_ state: StreakState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: streakKey)
        }
    }
    
    // MARK: - Streak Logic
    
    private func updateStreakOnCheckIn(for dateString: String) {
        var state = loadStreakState()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let checkInDate = formatter.date(from: dateString) else { return }
        let calendar = Calendar.current
        
        guard let lastDateString = state.lastCheckInDate,
              let lastDate = formatter.date(from: lastDateString) else {
            state.currentStreak = 1
            state.lastCheckInDate = dateString
            state.usedForgivenessInCurrentStreak = false
            saveStreakState(state)
            return
        }
        
        let daysBetween = calendar.dateComponents([.day], from: lastDate, to: checkInDate).day ?? 0
        
        if daysBetween == 0 {
            return
        }
        
        if daysBetween == 1 {
            state.currentStreak += 1
            state.lastCheckInDate = dateString
        } else if daysBetween == 2 && state.forgivenessRemaining > 0 {
            state.forgivenessUsedThisMonth += 1
            state.usedForgivenessInCurrentStreak = true
            state.currentStreak += 1
            state.lastCheckInDate = dateString
        } else {
            state.currentStreak = 1
            state.lastCheckInDate = dateString
            state.usedForgivenessInCurrentStreak = false
        }
        
        saveStreakState(state)
    }
    
    // MARK: - Streak Display Helpers
    
    func streakMessage() -> String? {
        let state = loadStreakState()
        
        guard state.currentStreak > 0 else { return nil }
        
        if state.usedForgivenessInCurrentStreak {
            return "You gave yourself grace this week."
        }
        
        if state.currentStreak >= 14 {
            return "You've made this a steady part of your rhythm."
        } else if state.currentStreak >= 7 {
            return "You've been checking in regularly."
        } else if state.currentStreak >= 3 {
            return "You're building a steady habit."
        }
        
        return nil
    }
    
    func streakResetMessage() -> String? {
        let state = loadStreakState()
        
        guard let lastDateString = state.lastCheckInDate,
              let lastDate = dateFromString(lastDateString) else {
            return nil
        }
        
        let today = Entry.todayString()
        guard let todayDate = dateFromString(today) else { return nil }
        
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: lastDate, to: todayDate).day ?? 0
        
        if daysSince > 2 && state.currentStreak <= 1 && state.forgivenessRemaining < 2 {
            return "You didn't lose progress. You're starting fresh."
        }
        
        return nil
    }
    
    private func dateFromString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
