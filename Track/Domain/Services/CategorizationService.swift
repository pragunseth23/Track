import Foundation

@MainActor
final class CategorizationService {
    private let categoryRepository: CategoryRepositoryProtocol
    
    init(categoryRepository: CategoryRepositoryProtocol) {
        self.categoryRepository = categoryRepository
    }
    
    func categorize(
        merchant: String,
        amount: Int
    ) async throws -> Category {
        // Normalize merchant name
        let normalized = normalizeMerchant(merchant)
        
        // Use rule-based categorization only
        let (categoryName, _) = ruleBasedCategorization(normalized, amount: amount)
        
        // Find or create category
        let allCategories = try await categoryRepository.fetchAll()
        if let category = allCategories.first(where: { $0.name == categoryName }) {
            return category
        }
        
        // Create new category if doesn't exist
        let newCategory = Category(name: categoryName, isSystem: false)
        try await categoryRepository.save(newCategory)
        return newCategory
    }
    
    private func normalizeMerchant(_ merchant: String) -> String {
        var normalized = merchant.trimmingCharacters(in: .whitespaces)
        
        // Remove common prefixes
        let prefixes = ["AMZN", "AMAZON", "SQ *", "SQ*", "PAYPAL", "APPLE", "GOOGLE"]
        for prefix in prefixes {
            if normalized.uppercased().hasPrefix(prefix) {
                normalized = String(normalized.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Remove numeric codes at end
        normalized = normalized.replacingOccurrences(of: #"\s+\d+$"#, with: "", options: .regularExpression)
        
        return normalized
    }
    
    private func ruleBasedCategorization(_ merchant: String, amount: Int) -> (String, Double) {
        let lowercased = merchant.lowercased()
        
        // High confidence rules
        let highConfidenceRules: [(String, [String])] = [
            ("Coffee", ["starbucks", "peets", "dunkin", "coffee", "cafe", "espresso"]),
            ("Groceries", ["whole foods", "safeway", "kroger", "trader joe", "walmart", "target", "costco", "grocery"]),
            ("Food", ["mcdonald", "burger", "pizza", "restaurant", "dining", "food", "eat"]),
            ("Transport", ["uber", "lyft", "taxi", "metro", "subway", "bus", "gas", "shell", "chevron", "exxon"]),
            ("Bills", ["electric", "water", "internet", "phone", "utility", "comcast", "verizon", "at&t"]),
            ("Health", ["pharmacy", "cvs", "walgreens", "doctor", "hospital", "medical", "dentist"]),
            ("Entertainment", ["netflix", "spotify", "hulu", "disney", "movie", "theater", "cinema"]),
            ("Shopping", ["amazon", "nike", "adidas", "mall", "store", "shop"]),
            ("Education", ["university", "college", "school", "course", "tuition"]),
            ("Travel", ["hotel", "airline", "airport", "booking", "expedia", "airbnb"]),
        ]
        
        for (category, keywords) in highConfidenceRules {
            if keywords.contains(where: { lowercased.contains($0) }) {
                return (category, 0.9)
            }
        }
        
        // Medium confidence rules
        let mediumConfidenceRules: [(String, [String])] = [
            ("Bills", ["subscription", "monthly", "recurring"]),
            ("Shopping", ["purchase", "order"]),
        ]
        
        for (category, keywords) in mediumConfidenceRules {
            if keywords.contains(where: { lowercased.contains($0) }) {
                return (category, 0.7)
            }
        }
        
        // Default fallback
        return ("Other", 0.5)
    }
}
