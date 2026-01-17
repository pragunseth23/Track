import SwiftUI
import SwiftData

struct MainTabView: View {
    @ObservedObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Int = 0
    
    private let tabs: [NavigationTab] = [
        NavigationTab(title: "Home", icon: "chart.line.uptrend.xyaxis"),
        NavigationTab(title: "Transactions", icon: "list.bullet"),
        NavigationTab(title: "Settings", icon: "gearshape.fill")
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content area
                Group {
                    switch selectedTab {
                    case 0:
                        HomeView(appState: appState)
                    case 1:
                        TransactionsView()
                    case 2:
                        SettingsView(appState: appState)
                    default:
                        HomeView(appState: appState)
                }
        }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom navigation bar
                BottomNavigationBar(selectedTab: $selectedTab, tabs: tabs)
            }
        }
        .onAppear {
            Task {
                await initializeCategories()
            }
        }
    }
    
    @MainActor
    private func initializeCategories() async {
        let categoryRepository = CategoryRepository(modelContext: modelContext)
        let initializationService = CategoryInitializationService(categoryRepository: categoryRepository)
        try? await initializationService.initializeIfNeeded()
    }
}
