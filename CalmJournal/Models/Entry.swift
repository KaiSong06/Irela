import Foundation

struct Entry: Codable, Identifiable {
    let id: UUID
    let date: String                    // YYYY-MM-DD
    let promptId: String
    let choice: String                  // Primary response
    let secondaryPromptId: String?      // Level 2+ follow-up prompt
    let secondaryResponse: String?      // Level 2+ follow-up response
    let tertiaryPromptId: String?       // Level 3 follow-up prompt
    let tertiaryResponse: String?       // Level 3 follow-up response
    let timestamp: TimeInterval
    
    // Standard initializer for new entries
    init(
        promptId: String,
        choice: String,
        secondaryPromptId: String? = nil,
        secondaryResponse: String? = nil,
        tertiaryPromptId: String? = nil,
        tertiaryResponse: String? = nil
    ) {
        self.id = UUID()
        self.date = Entry.todayString()
        self.promptId = promptId
        self.choice = choice
        self.secondaryPromptId = secondaryPromptId
        self.secondaryResponse = secondaryResponse
        self.tertiaryPromptId = tertiaryPromptId
        self.tertiaryResponse = tertiaryResponse
        self.timestamp = Date().timeIntervalSince1970
    }
    
    // Full initializer for cloud sync (preserves all fields)
    init(
        id: UUID,
        date: String,
        promptId: String,
        choice: String,
        secondaryPromptId: String? = nil,
        secondaryResponse: String? = nil,
        tertiaryPromptId: String? = nil,
        tertiaryResponse: String? = nil,
        timestamp: TimeInterval
    ) {
        self.id = id
        self.date = date
        self.promptId = promptId
        self.choice = choice
        self.secondaryPromptId = secondaryPromptId
        self.secondaryResponse = secondaryResponse
        self.tertiaryPromptId = tertiaryPromptId
        self.tertiaryResponse = tertiaryResponse
        self.timestamp = timestamp
    }
    
    static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // Helper to check if entry has context data
    var hasContextData: Bool {
        secondaryResponse != nil
    }
    
    // Helper to check if entry has deep data
    var hasDeepData: Bool {
        tertiaryResponse != nil
    }
}
