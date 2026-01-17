import SwiftUI

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @State private var currentPage = 0
    @State private var monthlyBudget: String = ""
    @State private var smartCategorizationEnabled = true
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1
            VStack(spacing: Spacing.xxl) {
                Spacer()
                Text("Track")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.textPrimary)
                Text("Understand where your money goes")
                    .font(.title2)
                    .foregroundColor(.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundPrimary)
            .tag(0)
            
            // Page 2
            VStack(spacing: Spacing.xxl) {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accent)
                Text("Private. On-device. No tracking.")
                    .font(.title2)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundPrimary)
            .tag(1)
            
            // Page 3
            VStack(spacing: Spacing.xl) {
                Spacer()
                VStack(spacing: Spacing.lg) {
                    Text("Optional Monthly Budget")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        Text("$")
                            .font(.numeric)
                            .foregroundColor(.textSecondary)
                        TextField("0", text: $monthlyBudget)
                            .font(.numeric)
                            .foregroundColor(.textPrimary)
                    }
                    .padding(Spacing.md)
                    .dataCard()
                    
                    Toggle("Smart Categorization", isOn: $smartCategorizationEnabled)
                        .foregroundColor(.textPrimary)
                }
                .padding(Spacing.xl)
                
                Button(action: {
                    let budget = monthlyBudget.isEmpty ? nil : Int(Double(monthlyBudget) ?? 0) * 100
                    appState.completeOnboarding(
                        monthlyBudget: budget,
                        smartCategorizationEnabled: smartCategorizationEnabled
                    )
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.backgroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .background(Color.accent)
                        .cornerRadius(CornerRadius.medium)
                }
                .padding(.horizontal, Spacing.xl)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundPrimary)
            .tag(2)
        }
        .tabViewStyle(.automatic)
    }
}
