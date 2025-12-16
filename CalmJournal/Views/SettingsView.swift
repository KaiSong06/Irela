import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDepth: DepthLevel = SettingsService.shared.depthLevel
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Text("How much depth\ndo you want?")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(DepthLevel.allCases, id: \.self) { level in
                        Button(action: {
                            selectedDepth = level
                            SettingsService.shared.depthLevel = level
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: selectedDepth == level ? "largecircle.fill.circle" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.5))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(level.title)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                                    
                                    Text(level.description)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedDepth == level ? Color(red: 0.4, green: 0.6, blue: 0.5).opacity(0.08) : Color.clear)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Text("Light is enough.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 180, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 0.4, green: 0.6, blue: 0.5))
                        )
                }
                .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SettingsView()
}

