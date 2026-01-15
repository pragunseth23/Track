import Foundation

@MainActor
final class CategoryInitializationService {
    private let categoryRepository: CategoryRepositoryProtocol
    private let userDefaults: UserDefaults
    
    init(categoryRepository: CategoryRepositoryProtocol, userDefaults: UserDefaults = .standard) {
        self.categoryRepository = categoryRepository
        self.userDefaults = userDefaults
    }
    
    func initializeIfNeeded() async throws {
        let hasInitialized = userDefaults.bool(forKey: "hasInitializedCategories")
        if hasInitialized {
            return
        }
        
        let defaultCategories = [
            "Food", "Groceries", "Coffee", "Transport", "Entertainment",
            "Shopping", "Bills", "Health", "Education", "Travel", "Other"
        ]
        
        for categoryName in defaultCategories {
            let category = Category(name: categoryName, isSystem: true)
            try await categoryRepository.save(category)
        }
        
        userDefaults.set(true, forKey: "hasInitializedCategories")
    }
}
