import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: Int
    let tabs: [NavigationTab]
    
    var body: some View {
        ZStack {
            // Technical framework background
            Color.surface
                .overlay(
                    Rectangle()
                        .fill(Color.dividerStrong)
                        .frame(height: 1),
                    alignment: .top
                )
            
            // Structured navigation buttons
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: selectedTab == index ? .semibold : .regular))
                                .foregroundColor(selectedTab == index ? .accent : .textSecondary)
                            
                            Text(tab.title)
                                .font(.labelSmall)
                                .foregroundColor(selectedTab == index ? .accent : .textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .contentShape(Rectangle())
                        .background(
                            selectedTab == index ? Color.accent.opacity(0.1) : Color.clear
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if index < tabs.count - 1 {
                        Rectangle()
                            .fill(Color.divider)
                            .frame(width: 1, height: 32)
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
        }
        .frame(height: 64)
    }
}

struct NavigationTab {
    let title: String
    let icon: String
}
