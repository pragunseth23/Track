import SwiftUI
import SwiftData

@main
struct TrackApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    MainTabView(appState: appState)
                        .onAppear {
                            Task {
                                await initializeApp()
                            }
                        }
                } else {
                    OnboardingView(appState: appState)
                }
            }
            .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Transaction.self, Category.self, Budget.self, Insight.self])
    }
    
    @MainActor
    private func initializeApp() async {
        // Categories will be initialized when needed via CategoryInitializationService
        // This is handled in the views that need it
    }
}
