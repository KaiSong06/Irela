import Foundation

struct Prompt: Identifiable {
    let id: String
    let text: String
    let options: [String]
    let levelRequired: Int  // 1 = all levels, 2 = Reflect+, 3 = Deep only
    let isPrimary: Bool     // true = main question, false = follow-up
    
    init(id: String, text: String, options: [String], levelRequired: Int = 1, isPrimary: Bool = true) {
        self.id = id
        self.text = text
        self.options = options
        self.levelRequired = levelRequired
        self.isPrimary = isPrimary
    }
}

// MARK: - Primary Prompts (Level 1+)
let primaryPrompts: [Prompt] = [
    Prompt(id: "today_felt", text: "Today felt:", options: ["😌 Calm", "😐 Neutral", "😵‍💫 Heavy"]),
    Prompt(id: "energy", text: "Energy today:", options: ["⚡ High", "🔋 Okay", "🪫 Low"]),
    Prompt(id: "mood", text: "Mood right now:", options: ["🙂 Good", "😐 Meh", "😔 Down"]),
    Prompt(id: "stress", text: "Stress level:", options: ["🟢 Low", "🟡 Medium", "🔴 High"]),
    Prompt(id: "clarity", text: "I feel:", options: ["🧠 Clear", "🌫 Foggy", "🔥 Overwhelmed"]),
    Prompt(id: "trend", text: "Today was:", options: ["👍 Better", "➖ Same", "👎 Worse"]),
    Prompt(id: "tomorrow", text: "Tomorrow I want:", options: ["🌱 Rest", "🎯 Focus", "🤝 Connect"])
]

// MARK: - Follow-Up Prompts (Level 2+)
let followUpPromptsLevel2: [Prompt] = [
    Prompt(id: "influence", text: "What shaped today most?", options: ["💼 Work", "👥 People", "🏠 Home"], levelRequired: 2, isPrimary: false),
    Prompt(id: "pace", text: "The day felt:", options: ["🏃 Busy", "⚖️ Steady", "🐢 Slow"], levelRequired: 2, isPrimary: false),
    Prompt(id: "focus_area", text: "Where did today land?", options: ["💼 Work", "❤️ Personal", "🔄 Both"], levelRequired: 2, isPrimary: false),
    Prompt(id: "connection", text: "Today I felt:", options: ["🤝 Connected", "🧍 Solo", "😶 Distant"], levelRequired: 2, isPrimary: false)
]

// MARK: - Deep Follow-Ups (Level 3 only)
let followUpPromptsLevel3: [Prompt] = [
    Prompt(id: "body", text: "Your body felt:", options: ["😌 Relaxed", "😬 Tense", "😩 Drained"], levelRequired: 3, isPrimary: false),
    Prompt(id: "sleep", text: "Sleep last night:", options: ["😴 Good", "😐 Okay", "😵 Poor"], levelRequired: 3, isPrimary: false),
    Prompt(id: "rest", text: "Did you get rest?", options: ["✅ Yes", "🤷 Some", "❌ No"], levelRequired: 3, isPrimary: false),
    Prompt(id: "carry", text: "Carrying anything heavy?", options: ["🪶 Light", "📦 Some", "🏋️ A lot"], levelRequired: 3, isPrimary: false)
]

let prompts = primaryPrompts

func todaysPrompt() -> Prompt {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    return primaryPrompts[(dayOfYear - 1) % primaryPrompts.count]
}

func todaysFollowUpLevel2() -> Prompt {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    return followUpPromptsLevel2[(dayOfYear + 2) % followUpPromptsLevel2.count]
}

func todaysFollowUpLevel3() -> Prompt {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    return followUpPromptsLevel3[(dayOfYear + 4) % followUpPromptsLevel3.count]
}
