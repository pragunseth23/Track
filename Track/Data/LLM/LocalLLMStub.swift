import Foundation

final class LocalLLMStub: LLMClient {
    func categorize(merchant: String, amount: Int, existingCategories: [String]) async throws -> String {
        // Deterministic fallback - returns "Other" as default
        return "Other"
    }
}
