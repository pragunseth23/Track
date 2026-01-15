import Foundation

protocol LLMClient {
    func categorize(merchant: String, amount: Int, existingCategories: [String]) async throws -> String
}
