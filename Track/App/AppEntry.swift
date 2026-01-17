import SwiftUI
import SwiftData
import PythonKit

@main
struct TrackApp: App {
    @StateObject private var appState = AppState()
    
    private static let pythonInitLock = NSLock()
    private static var isPythonInitialized = false
    
    init() {
        Self.initializePythonSafely()
    }
    
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
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        .modelContainer(for: [Transaction.self, Category.self, Insight.self])
    }
    
    private static func initializePythonSafely() {
        pythonInitLock.lock()
        defer { pythonInitLock.unlock() }
        
        guard !isPythonInitialized else { return }
        
        do {
            _ = try Python.attemptImport("sys")
            isPythonInitialized = true
        } catch {
            // Will retry when needed via MLXLLMClient
        }
    }
    
    static var isPythonReady: Bool {
        pythonInitLock.lock()
        defer { pythonInitLock.unlock() }
        return isPythonInitialized
    }
    
    @MainActor
    private func initializeApp() async {
        // Categories initialized when needed via CategoryInitializationService
    }
}
