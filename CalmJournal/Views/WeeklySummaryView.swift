import SwiftUI

struct WeeklySummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var insights: [String] = []
    @State private var isLoading = true
    
    private let storage = StorageService.shared
    private var depthLevel: DepthLevel { SettingsService.shared.depthLevel }
    
    private var entries: [Entry] {
        storage.lastSevenDays()
    }
    
    // Level 1 insights for safe sharing (fallback to static for sharing)
    private var shareInsights: [String] {
        insights.isEmpty ? WeeklySummaryView.generateInsights(from: entries, depth: .light) : insights
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Back button row
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    // Dino character
                    DinoCharacter(mood: .winking, size: 100)
                        .padding(.top, 8)
                    
                    // Title
                    Text("This week")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    // Insights
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Reflecting on your week...")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(insights, id: \.self) { insight in
                                Text(insight)
                                    .font(.system(size: 17, weight: .regular, design: .serif))
                                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    // Streak message (subtle, below insights)
                    if let streakMessage = storage.streakMessage() {
                        Text(streakMessage)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Reset message (if applicable)
                    if let resetMessage = storage.streakResetMessage() {
                        Text(resetMessage)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    Spacer().frame(height: 20)
                    
                    // Share button
                    Button(action: shareRecap) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                            Text("Share your week")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.5))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .stroke(Color(red: 0.4, green: 0.6, blue: 0.5), lineWidth: 1.5)
                        )
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadInsights()
        }
    }
    
    // MARK: - AI Insight Loading
    
    private func loadInsights() async {
        isLoading = true
        
        // Try AI generation first
        if let aiInsights = await GeminiService.shared.generateWeeklyInsights(from: entries, depth: depthLevel) {
            await MainActor.run {
                insights = aiInsights
                isLoading = false
            }
        } else {
            // Fallback to static insights if AI fails
            await MainActor.run {
                insights = WeeklySummaryView.generateInsights(from: entries, depth: depthLevel)
                isLoading = false
            }
        }
    }
    
    // MARK: - Share
    
    private func shareRecap() {
        let recapView = RecapCardView(insights: shareInsights)
        let image = recapView.renderAsImage()
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Insight Generation
    
    static func generateInsights(from entries: [Entry], depth: DepthLevel) -> [String] {
        guard !entries.isEmpty else {
            return ["No check-ins yet this week.", "Come back after a few days."]
        }
        
        var insights: [String] = []
        
        // Most frequent mood (primary)
        let choices = entries.map { $0.choice }
        let frequency = Dictionary(grouping: choices, by: { $0 }).mapValues { $0.count }
        
        if let dominant = frequency.max(by: { $0.value < $1.value })?.key {
            let dominantLower = dominant.lowercased()
            
            if dominantLower.contains("calm") || dominantLower.contains("good") || dominantLower.contains("clear") {
                insights.append("This week felt mostly calm.")
            } else if dominantLower.contains("heavy") || dominantLower.contains("down") || dominantLower.contains("overwhelmed") {
                insights.append("This week carried some weight.")
            } else if dominantLower.contains("neutral") || dominantLower.contains("meh") || dominantLower.contains("okay") {
                insights.append("This week moved at its own pace.")
            } else {
                insights.append("This week had its moments.")
            }
        }
        
        // Weekday vs weekend contrast
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var weekdayChoices: [String] = []
        var weekendChoices: [String] = []
        
        for entry in entries {
            if let date = formatter.date(from: entry.date) {
                let weekday = calendar.component(.weekday, from: date)
                if weekday == 1 || weekday == 7 {
                    weekendChoices.append(entry.choice)
                } else {
                    weekdayChoices.append(entry.choice)
                }
            }
        }
        
        if !weekdayChoices.isEmpty && !weekendChoices.isEmpty {
            let weekdayHeavy = weekdayChoices.filter { $0.lowercased().contains("heavy") || $0.lowercased().contains("down") || $0.lowercased().contains("overwhelmed") }.count
            let weekendHeavy = weekendChoices.filter { $0.lowercased().contains("heavy") || $0.lowercased().contains("down") || $0.lowercased().contains("overwhelmed") }.count
            
            let weekdayRatio = Double(weekdayHeavy) / Double(weekdayChoices.count)
            let weekendRatio = weekendChoices.isEmpty ? 0 : Double(weekendHeavy) / Double(weekendChoices.count)
            
            if weekdayRatio > weekendRatio + 0.3 {
                insights.append("Weekdays felt heavier than the weekend.")
            } else if weekendRatio > weekdayRatio + 0.3 {
                insights.append("The weekend was heavier than weekdays.")
            }
        }
        
        // Level 2+: Pattern callouts from secondary responses
        if depth.rawValue >= 2 {
            let secondaryResponses = entries.compactMap { $0.secondaryResponse }
            if !secondaryResponses.isEmpty {
                let secFrequency = Dictionary(grouping: secondaryResponses, by: { $0 }).mapValues { $0.count }
                if let dominant = secFrequency.max(by: { $0.value < $1.value })?.key,
                   let count = secFrequency[dominant], count >= 3 {
                    if dominant.lowercased().contains("work") {
                        insights.append("Work shaped a lot of your week.")
                    } else if dominant.lowercased().contains("people") {
                        insights.append("People were a big influence this week.")
                    } else if dominant.lowercased().contains("busy") {
                        insights.append("The pace was busy this week.")
                    }
                }
            }
        }
        
        // Level 3: Deeper connections from tertiary responses
        if depth == .deep {
            let tertiaryResponses = entries.compactMap { $0.tertiaryResponse }
            if !tertiaryResponses.isEmpty {
                let tenseDays = tertiaryResponses.filter { $0.lowercased().contains("tense") || $0.lowercased().contains("drained") }.count
                if tenseDays >= 2 {
                    insights.append("Your body held some tension this week.")
                }
            }
        }
        
        // Completion message
        let count = entries.count
        if count >= 5 {
            insights.append("You showed up \(count) days. That's enough.")
        } else if count >= 3 {
            insights.append("You checked in \(count) times this week.")
        } else if count == 1 {
            insights.append("You checked in once. That counts.")
        } else {
            insights.append("You checked in \(count) times. Every one matters.")
        }
        
        // Limit based on depth
        let maxInsights: Int
        switch depth {
        case .light:  maxInsights = 3
        case .reflect: maxInsights = 4
        case .deep:    maxInsights = 5
        }
        
        return Array(insights.prefix(maxInsights))
    }
}

#Preview {
    WeeklySummaryView()
}

