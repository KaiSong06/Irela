import SwiftUI

/// Mood states for the dino character
enum DinoMood: String {
    case loving = "dino_loving"
    case thinking = "dino_thinking"
    case worried = "dino_worried"
    case shy = "dino_shy"
    case happy = "dino_happy"
    case winking = "dino_winking"
    
    /// Emoji fallback when image assets aren't available
    var emojiFallback: String {
        switch self {
        case .loving:   return "🥰"
        case .thinking: return "🤔"
        case .worried:  return "🥺"
        case .shy:      return "😊"
        case .happy:    return "😄"
        case .winking:  return "😉"
        }
    }
    
    /// Map user's choice to a dino mood
    static func from(choice: String) -> DinoMood {
        let lower = choice.lowercased()
        
        // Positive responses
        if lower.contains("calm") || lower.contains("good") || lower.contains("high") || 
           lower.contains("low") && lower.contains("stress") || lower.contains("clear") || 
           lower.contains("better") || lower.contains("relaxed") {
            return .happy
        }
        
        // Heavy/negative responses
        if lower.contains("heavy") || lower.contains("down") || lower.contains("overwhelmed") || 
           lower.contains("worse") || lower.contains("drained") || lower.contains("tense") {
            return .worried
        }
        
        // Neutral/thinking
        return .thinking
    }
}

/// Cute dino character that reacts to user mood
struct DinoCharacter: View {
    let mood: DinoMood
    var size: CGFloat = 100
    
    @State private var isAnimating = false
    
    var body: some View {
        // Try to load image asset, fall back to emoji
        if let uiImage = UIImage(named: mood.rawValue) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .modifier(BouncingAnimation())
        } else {
            // Emoji fallback with soft circle background
            ZStack {
                Circle()
                    .fill(Color(red: 0.4, green: 0.6, blue: 0.5).opacity(0.15))
                    .frame(width: size, height: size)
                
                Text(mood.emojiFallback)
                    .font(.system(size: size * 0.55))
            }
            .modifier(BouncingAnimation())
        }
    }
}

/// Subtle bouncing animation modifier
struct BouncingAnimation: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.03 : 1.0)
            .animation(
                Animation.easeInOut(duration: 2.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    VStack(spacing: 30) {
        DinoCharacter(mood: .happy, size: 120)
        DinoCharacter(mood: .worried, size: 100)
        DinoCharacter(mood: .thinking, size: 80)
    }
}

