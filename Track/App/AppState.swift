import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var monthlyBudget: Int?
    @Published var smartCategorizationEnabled: Bool
    @Published var modelDownloader: ModelDownloader
    
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: "hasCompletedOnboarding")
        self.monthlyBudget = userDefaults.object(forKey: "monthlyBudget") as? Int
        self.smartCategorizationEnabled = userDefaults.bool(forKey: "smartCategorizationEnabled")
        self.modelDownloader = ModelDownloader()
    }
    
    func completeOnboarding(monthlyBudget: Int?, smartCategorizationEnabled: Bool) {
        self.hasCompletedOnboarding = true
        self.monthlyBudget = monthlyBudget
        self.smartCategorizationEnabled = smartCategorizationEnabled
        
        userDefaults.set(true, forKey: "hasCompletedOnboarding")
        if let budget = monthlyBudget {
            userDefaults.set(budget, forKey: "monthlyBudget")
        }
        userDefaults.set(smartCategorizationEnabled, forKey: "smartCategorizationEnabled")
    }
    
    func updateSmartCategorization(_ enabled: Bool) {
        self.smartCategorizationEnabled = enabled
        userDefaults.set(enabled, forKey: "smartCategorizationEnabled")
    }
}
