import Foundation

final class LocalLLMStub: LLMClient {
    func categorize(merchant: String, amount: Int) async throws -> String {
        // Deterministic fallback - returns "Other" as default
        return "Other"
    }
    
    func generateInsight(transactionSummary: String) async throws -> String {
        // Fallback insight - parse summary and provide basic analysis
        // This is a simple fallback when the AI model isn't available
        if transactionSummary.contains("Total spending") {
            return "Review your spending patterns to identify areas for improvement. Consider tracking your top spending categories and look for opportunities to reduce costs in areas where you spend the most."
        }
        return "Start tracking your transactions to get personalized insights about your spending habits and financial health."
    }
}
