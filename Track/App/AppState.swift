import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var monthlyBudget: Int?
    
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: "hasCompletedOnboarding")
        self.monthlyBudget = userDefaults.object(forKey: "monthlyBudget") as? Int
    }
    
    func completeOnboarding(monthlyBudget: Int?) {
        self.hasCompletedOnboarding = true
        self.monthlyBudget = monthlyBudget
        
        userDefaults.set(true, forKey: "hasCompletedOnboarding")
        if let budget = monthlyBudget {
            userDefaults.set(budget, forKey: "monthlyBudget")
        }
    }
    
    func createLLMClient() -> LLMClient {
        return OnDeviceLLMClient()
    }
}
