import Foundation

enum LLMError: Error, LocalizedError {
    case modelLoadFailed(String)
    case modelNotLoaded
    case inferenceFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let message): return "Model Load Failed: \(message)"
        case .modelNotLoaded: return "LLM Model Not Loaded"
        case .inferenceFailed(let message): return "LLM Inference Failed: \(message)"
        }
    }
}

protocol LLMClient {
    func categorize(merchant: String, amount: Int) async throws -> String
    func generateInsight(transactionSummary: String) async throws -> String
}
