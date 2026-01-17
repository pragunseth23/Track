import Foundation
import PythonKit

/// Client for running Phi-3.5-mini-instruct model inference using MLX via Python mlx-lm
nonisolated final class MLXLLMClient: LLMClient, @unchecked Sendable {
    private let modelURL: URL
    private var pythonModel: PythonObject?
    private var pythonTokenizer: PythonObject?
    
    init(modelURL: URL) {
        self.modelURL = modelURL
    }
    
    /// Ensure Python is initialized
    nonisolated private static func ensurePythonInitialized() throws {
        if TrackApp.isPythonReady {
            _ = try Python.attemptImport("sys")
            return
        }
        
        if Thread.isMainThread {
            _ = try Python.attemptImport("sys")
        } else {
            var initError: Error?
            let semaphore = DispatchSemaphore(value: 0)
            
            DispatchQueue.main.async {
                do {
                    _ = try Python.attemptImport("sys")
                } catch {
                    initError = error
                }
                semaphore.signal()
            }
            
            if semaphore.wait(timeout: .now() + 5.0) == .timedOut {
                throw LLMError.modelLoadFailed("Python initialization timed out")
            }
            
            if let error = initError {
                throw LLMError.modelLoadFailed("Python initialization failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Initialize Python environment and ensure mlx-lm is available
    nonisolated private func ensurePythonEnvironment() throws {
        try Self.ensurePythonInitialized()
        _ = try Python.attemptImport("mlx_lm")
    }
    
    /// Load the model and tokenizer if not already loaded
    nonisolated private func ensureModelLoaded() async throws {
        guard pythonModel == nil || pythonTokenizer == nil else { return }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LLMError.modelLoadFailed("Client deallocated"))
                    return
                }
                
                guard self.pythonModel == nil || self.pythonTokenizer == nil else {
                    continuation.resume()
                    return
                }
                
                guard FileManager.default.fileExists(atPath: self.modelURL.path) else {
                    continuation.resume(throwing: LLMError.modelLoadFailed("Model directory not found"))
                    return
                }
                
                do {
                    try self.ensurePythonEnvironment()
                    
                    let mlx_lm = try Python.attemptImport("mlx_lm")
                    let modelPath = self.modelURL.path
                    
                    // Verify required files exist
                    for fileName in ["config.json", "tokenizer.json"] {
                        let filePath = (modelPath as NSString).appendingPathComponent(fileName)
                        guard FileManager.default.fileExists(atPath: filePath) else {
                            continuation.resume(throwing: LLMError.modelLoadFailed("Required file missing: \(fileName)"))
                            return
                        }
                    }
                    
                    // Load model and tokenizer
                    let loaded = mlx_lm.load(PythonObject(modelPath))
                    self.pythonModel = loaded[0]
                    self.pythonTokenizer = loaded[1]
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: LLMError.modelLoadFailed("Failed to load model: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    func categorize(merchant: String, amount: Int) async throws -> String {
        try await ensureModelLoaded()
        
        let prompt = """
        <|user|>
        You are a financial transaction categorization assistant. Analyze the following transaction and suggest the most appropriate spending category.
        
        Merchant: \(merchant)
        Amount: $\(String(format: "%.2f", Double(abs(amount)) / 100.0))
        
        Respond with only a JSON object in this format:
        {"category": "CategoryName"}
        
        Suggest a clear, specific category name (e.g., "Coffee", "Groceries", "Transport", "Entertainment", "Food", "Shopping", "Bills", "Health", "Education", "Travel", "Subscriptions", etc.). Choose the most appropriate category based on the merchant name and amount.<|end|>
        <|assistant|>
        """
        
        let response = try await generateResponse(prompt: prompt, maxTokens: 128)
        
        if let category = JSONGuard.extractCategory(from: response) {
            return category
        }
        
        return extractCategoryFromText(response)
    }
    
    func generateInsight(transactionSummary: String) async throws -> String {
        try await ensureModelLoaded()
        
        let prompt = """
        <|user|>
        You are an expert financial advisor analyzing personal spending data. Provide a detailed, actionable insight (4-6 sentences) that:
        1. Identifies key spending patterns and trends
        2. Highlights notable changes or anomalies
        3. Provides specific, actionable recommendations
        4. Mentions specific categories or amounts when relevant
        5. Suggests concrete ways to improve financial health
        
        Be specific, helpful, and conversational. Focus on insights the user can act on immediately.
        
        Transaction Summary:
        \(transactionSummary)
        
        Provide your detailed financial insight:<|end|>
        <|assistant|>
        """
        
        return try await generateResponse(prompt: prompt, maxTokens: 512)
    }
    
    // MARK: - Helper methods
    
    nonisolated private func generateResponse(prompt: String, maxTokens: Int = 256) async throws -> String {
        guard let model = pythonModel, let tokenizer = pythonTokenizer else {
            throw LLMError.modelNotLoaded
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            DispatchQueue.main.async {
                do {
                    let mlx_lm = try Python.attemptImport("mlx_lm")
                    // mlx_lm.generate() signature: generate(model, tokenizer, prompt, max_tokens=...)
                    // Note: temperature parameter may not be supported in all versions
                    let response = mlx_lm.generate(
                        model,
                        tokenizer,
                        PythonObject(prompt),
                        max_tokens: PythonObject(maxTokens)
                    )
                    
                    let responseString = String(response) ?? ""
                    continuation.resume(returning: responseString.trimmingCharacters(in: .whitespacesAndNewlines))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func extractCategoryFromText(_ text: String) -> String {
        let lowercased = text.lowercased()
        let commonCategories = ["coffee", "groceries", "food", "transport", "entertainment", "shopping", "bills", "health", "education", "travel", "subscriptions", "other"]
        
        for category in commonCategories {
            if lowercased.contains(category) {
                return category.capitalized
            }
        }
        
        return "Other"
    }
}
