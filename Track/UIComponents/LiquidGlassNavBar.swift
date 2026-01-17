import SwiftUI

struct LiquidGlassNavBar: View {
    @Binding var selectedTab: Int
    let tabs: [NavTab]
    
    var body: some View {
        ZStack {
            // Background
            ZStack {
                // Liquid glass effect
                Color.black.opacity(0.4)
                    .background(.ultraThinMaterial)
                
                // Top border
                VStack {
                    Divider()
                        .background(Color.borderPrimary)
                    Spacer()
                }
            }
            
            // Buttons and glow
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    ZStack {
                        // Glow effect behind selected tab
                        if selectedTab == index {
                            Circle()
                                .fill(Color.accent.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .blur(radius: 20)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                        }
                        
                        // Button content
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20, weight: selectedTab == index ? .semibold : .regular))
                                    .foregroundColor(selectedTab == index ? .accent : .textSecondary)
                                    .symbolEffect(.bounce, value: selectedTab == index)
                                
                                Text(tab.title)
                                    .font(.labelSmall)
                                    .foregroundColor(selectedTab == index ? .accent : .textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    
                    if index < tabs.count - 1 {
                        Divider()
                            .frame(height: 30)
                            .background(Color.divider)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .frame(height: 70)
    }
}

struct NavTab {
    let title: String
    let icon: String
}
