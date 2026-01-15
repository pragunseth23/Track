import Foundation

// Placeholder for CoreML/MLX Swift integration
final class OnDeviceLLMClient: LLMClient {
    func categorize(merchant: String, amount: Int, existingCategories: [String]) async throws -> String {
        // TODO: Implement CoreML/MLX Swift integration
        // For now, fallback to stub
        return try await LocalLLMStub().categorize(merchant: merchant, amount: amount, existingCategories: existingCategories)
    }
}
