import SwiftUI

struct CheckInView: View {
    @State private var selectedChoice: String?
    @State private var showConfirmation = false
    @State private var hasCheckedIn = false
    
    // Multi-step check-in state
    @State private var currentStep = 0  // 0 = primary, 1 = secondary, 2 = tertiary
    @State private var primaryResponse: String?
    @State private var secondaryResponse: String?
    @State private var tertiaryResponse: String?
    
    // Dino mood
    @State private var dinoMood: DinoMood = .shy
    
    private let storage = StorageService.shared
    private var depthLevel: DepthLevel { SettingsService.shared.depthLevel }
    
    private var prompt: Prompt { todaysPrompt() }
    
    var body: some View {
        ZStack {
            // Warm, calm background
            Color(red: 0.98, green: 0.97, blue: 0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Dino character
                DinoCharacter(mood: dinoMood, size: 100)
                    .padding(.bottom, 8)
                
                if hasCheckedIn {
                    completedView
                } else {
                    promptView
                }
                
                Spacer()
                
                // Weekly recap link (shows when there's any check-in data)
                if !storage.lastSevenDays().isEmpty {
                    NavigationLink(destination: WeeklySummaryView()) {
                        HStack(spacing: 6) {
                            Text("This week")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.4, green: 0.6, blue: 0.5).opacity(0.12))
                        )
                    }
                    .padding(.bottom, 40)
                }
            }
            .padding(.horizontal, 24)
            
            // Back button & Settings (top bar)
            VStack {
                HStack {
                    // Back button (only when on follow-up or already checked in)
                    if hasCheckedIn || currentStep > 0 {
                        Button(action: goBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(12)
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }
                    
                    Spacer()
                    
                    // Settings button
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(12)
                    }
                }
                .padding(.horizontal, 8)
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkTodaysEntry()
        }
    }
    
    // MARK: - Prompt View (Multi-step)
    
    private var promptView: some View {
        VStack(spacing: 32) {
            Text(currentPromptText)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(currentPromptOptions, id: \.self) { option in
                    Button(action: {
                        selectOption(option)
                    }) {
                        Text(option)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                            )
                    }
                }
                
                // "That's enough" skip for follow-ups
                if currentStep > 0 {
                    Button(action: finishCheckIn) {
                        Text("That's enough")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - Completed View
    
    private var completedView: some View {
        VStack(spacing: 24) {
            Text("You've checked in today.")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
            
            if let choice = selectedChoice {
                Text(choice)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if showConfirmation {
                Text("Saved")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.5))
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Dynamic Prompt Content
    
    private var currentPromptText: String {
        switch currentStep {
        case 0:
            return prompt.text
        case 1:
            return todaysFollowUpLevel2().text
        case 2:
            return todaysFollowUpLevel3().text
        default:
            return prompt.text
        }
    }
    
    private var currentPromptOptions: [String] {
        switch currentStep {
        case 0:
            return prompt.options
        case 1:
            return todaysFollowUpLevel2().options
        case 2:
            return todaysFollowUpLevel3().options
        default:
            return prompt.options
        }
    }
    
    // MARK: - Actions
    
    private func selectOption(_ option: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case 0:
                primaryResponse = option
                selectedChoice = option
                dinoMood = DinoMood.from(choice: option)
                
                // Check if we should show follow-up
                if depthLevel.rawValue >= 2 {
                    currentStep = 1
                } else {
                    finishCheckIn()
                }
                
            case 1:
                secondaryResponse = option
                
                // Check if we should show second follow-up
                if depthLevel == .deep {
                    currentStep = 2
                } else {
                    finishCheckIn()
                }
                
            case 2:
                tertiaryResponse = option
                finishCheckIn()
                
            default:
                break
            }
        }
    }
    
    private func finishCheckIn() {
        guard let primary = primaryResponse else { return }
        
        let entry = Entry(
            promptId: prompt.id,
            choice: primary,
            secondaryPromptId: currentStep >= 1 ? todaysFollowUpLevel2().id : nil,
            secondaryResponse: secondaryResponse,
            tertiaryPromptId: currentStep >= 2 ? todaysFollowUpLevel3().id : nil,
            tertiaryResponse: tertiaryResponse
        )
        
        storage.save(entry)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCheckedIn = true
            showConfirmation = true
            dinoMood = .happy
        }
        
        // Hide confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showConfirmation = false
            }
        }
    }
    
    private func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if hasCheckedIn {
                // Going back from completed state
                hasCheckedIn = false
                showConfirmation = false
                
                // Restore state based on depth level
                if depthLevel == .deep && tertiaryResponse != nil {
                    currentStep = 2
                } else if depthLevel.rawValue >= 2 && secondaryResponse != nil {
                    currentStep = 1
                } else {
                    currentStep = 0
                }
                dinoMood = .shy
            } else if currentStep > 0 {
                // Going back to previous step
                currentStep -= 1
                if currentStep == 0 {
                    secondaryResponse = nil
                    tertiaryResponse = nil
                } else if currentStep == 1 {
                    tertiaryResponse = nil
                }
            }
        }
    }
    
    private func checkTodaysEntry() {
        if let entry = storage.todaysEntry() {
            selectedChoice = entry.choice
            primaryResponse = entry.choice
            secondaryResponse = entry.secondaryResponse
            tertiaryResponse = entry.tertiaryResponse
            hasCheckedIn = true
            dinoMood = DinoMood.from(choice: entry.choice)
        }
    }
}

#Preview {
    NavigationStack {
        CheckInView()
    }
}

