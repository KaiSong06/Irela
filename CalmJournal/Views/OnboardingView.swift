import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Warm background
            Color(red: 0.98, green: 0.97, blue: 0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                if currentPage == 0 {
                    welcomeView
                } else {
                    notificationView
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomeView: some View {
        VStack(spacing: 32) {
            // Dino character
            DinoCharacter(mood: .loving, size: 120)
            
            Text("This takes 3 seconds a day.")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                .multilineTextAlignment(.center)
            
            Text("One tap. No typing. Just check in.")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage = 1
                }
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .fill(Color(red: 0.4, green: 0.6, blue: 0.5))
                    )
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Page 2: Notification Permission
    
    private var notificationView: some View {
        VStack(spacing: 32) {
            // Dino character
            DinoCharacter(mood: .thinking, size: 120)
            
            Text("A gentle reminder?")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                .multilineTextAlignment(.center)
            
            Text("One quiet nudge each evening.\nNo pressure.")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                Button(action: {
                    NotificationService.shared.requestPermission { _ in
                        completeOnboarding()
                    }
                }) {
                    Text("Enable Reminders")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(Color(red: 0.4, green: 0.6, blue: 0.5))
                        )
                }
                
                Button(action: {
                    completeOnboarding()
                }) {
                    Text("Not now")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 20)
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
