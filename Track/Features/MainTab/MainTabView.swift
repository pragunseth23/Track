import SwiftUI
import SwiftData

struct MainTabView: View {
    @ObservedObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            HomeView(appState: appState)
                .tabItem {
                    Image(systemName: "house.fill")
                }
            
            TransactionsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                }
            
            BudgetsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                }
            
            SettingsView(appState: appState)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                }
        }
        .accentColor(.accent)
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
