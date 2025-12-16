import SwiftUI

/// Story-optimized share card (9:16 / 1080x1920)
struct RecapCardView: View {
    let insights: [String]
    
    var body: some View {
        ZStack {
            // Soft gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.95),
                    Color(red: 0.95, green: 0.93, blue: 0.90)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 40) {
                Spacer()
                
                // Dino character
                DinoCharacter(mood: .winking, size: 120)
                
                VStack(spacing: 24) {
                    ForEach(insights, id: \.self) { insight in
                        Text(insight)
                            .font(.custom("Georgia", size: 32))
                            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 60)
                    }
                }
                
                Spacer()
                
                // Subtle app name
                Text("Calm Journal")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 80)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Render to Image

extension View {
    @MainActor
    func renderAsImage() -> UIImage {
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        let view = controller.view!
        
        let targetSize = CGSize(width: 1080, height: 1920)
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
}

#Preview {
    RecapCardView(insights: [
        "This week felt mostly calm.",
        "Midweek was heavier than the weekend.",
        "You showed up 5 days. That's enough."
    ])
    .frame(width: 270, height: 480)
    .scaleEffect(0.25)
}

