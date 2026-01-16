import Foundation
import Combine

final class OnDeviceLLMClient: LLMClient {
    private let modelDownloader: ModelDownloader
    private var gemmaClient: GemmaLLMClient?
    private let fallbackClient = LocalLLMStub()
    private var cancellables = Set<AnyCancellable>()
    
    init(modelDownloader: ModelDownloader) {
        self.modelDownloader = modelDownloader
        loadModelIfAvailable()
        
        // Observe model download state changes
        modelDownloader.$downloadState
            .sink { [weak self] state in
                if case .downloaded = state {
                    self?.loadModelIfAvailable()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadModelIfAvailable() {
        if let modelURL = modelDownloader.getModelURL() {
            gemmaClient = GemmaLLMClient(modelURL: modelURL)
        } else {
            gemmaClient = nil
        }
    }
    
    func categorize(merchant: String, amount: Int, existingCategories: [String]) async throws -> String {
        // Try to use Gemma model if available
        if let gemmaClient = gemmaClient {
            do {
                return try await gemmaClient.categorize(
                    merchant: merchant,
                    amount: amount,
                    existingCategories: existingCategories
                )
            } catch {
                // Fallback to stub if inference fails
                print("Gemma inference failed: \(error.localizedDescription), falling back to stub")
            }
        }
        
        // Fallback to stub
        return try await fallbackClient.categorize(
            merchant: merchant,
            amount: amount,
            existingCategories: existingCategories
        )
    }
    
    func reloadModel() {
        loadModelIfAvailable()
    }
}

// Helper extension to create LLM client from AppState
extension AppState {
    func createLLMClient() -> LLMClient {
        return OnDeviceLLMClient(modelDownloader: modelDownloader)
    }
}
