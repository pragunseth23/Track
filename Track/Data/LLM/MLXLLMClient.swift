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
        let mlx_lm = try Python.attemptImport("mlx_lm")
        
        // Verify GPU/Metal is available (MLX uses GPU by default on Apple Silicon)
        do {
            let mlx = try Python.attemptImport("mlx.core")
            // Check if GPU is available
            let hasGPU = try mlx.metal.is_available()
            // Convert Python bool to Swift Bool
            if Bool(hasGPU) == true {
                // Get current default device to verify
                let currentDevice = mlx.default_device()
                print("✅ [MLXLLMClient] GPU (Metal) is available")
                print("✅ [MLXLLMClient] Current device: \(currentDevice)")
                // MLX automatically uses GPU on Apple Silicon, no need to set explicitly
            } else {
                print("⚠️ [MLXLLMClient] GPU (Metal) not available, will use CPU")
            }
        } catch {
            print("⚠️ [MLXLLMClient] Could not verify GPU device: \(error.localizedDescription)")
        }
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
                    let mlx = try Python.attemptImport("mlx.core")
                    let modelPath = self.modelURL.path
                    
                    // Verify required files exist
                    for fileName in ["config.json", "tokenizer.json"] {
                        let filePath = (modelPath as NSString).appendingPathComponent(fileName)
                        guard FileManager.default.fileExists(atPath: filePath) else {
                            continuation.resume(throwing: LLMError.modelLoadFailed("Required file missing: \(fileName)"))
                            return
                        }
                    }
                    
                    // Verify GPU availability (MLX uses GPU by default on Apple Silicon)
                    let hasGPU = try mlx.metal.is_available()
                    if Bool(hasGPU) == true {
                        print("✅ [MLXLLMClient] Loading model on GPU (Metal)")
                    } else {
                        print("⚠️ [MLXLLMClient] GPU not available, loading on CPU")
                    }
                    
                    // Load model and tokenizer (will use default device set above)
                    let loaded = mlx_lm.load(PythonObject(modelPath))
                    self.pythonModel = loaded[0]
                    self.pythonTokenizer = loaded[1]
                    
                    print("✅ [MLXLLMClient] Model loaded successfully")
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: LLMError.modelLoadFailed("Failed to load model: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    func generateInsight(transactionSummary: String) async throws -> String {
        try await ensureModelLoaded()
        
        print("🤖 [MLXLLMClient] Generating AI insight from transaction summary...")
        print("📋 [MLXLLMClient] Summary length: \(transactionSummary.count) characters")
        
        // Add variety by including different analysis angles
        let analysisAngles = [
            "Focus on spending efficiency and optimization opportunities",
            "Highlight trends and patterns with actionable recommendations",
            "Emphasize category-specific insights and spending patterns",
            "Analyze subscription costs and recurring expense optimization",
            "Compare month-over-month changes with specific improvement areas"
        ]
        let selectedAngle = analysisAngles.randomElement() ?? analysisAngles[0]
        
        let prompt = """
        <|user|>
        You are an expert financial advisor analyzing personal spending data. Provide a concise, actionable financial insight in bullet point format (4-6 bullet points).
        
        Analysis focus: \(selectedAngle)
        
        Requirements:
        - Format as bullet points (use • or -)
        - Each bullet should be specific and actionable
        - Mention specific categories, amounts, or percentages when relevant
        - Provide variety in recommendations (not all the same type)
        - Be creative and insightful, not generic
        - Keep each bullet point to 1-2 sentences max
        
        Transaction Summary:
        \(transactionSummary)
        
        Provide your financial insight in bullet point format:<|end|>
        <|assistant|>
        """
        
        let response = try await generateResponse(prompt: prompt, maxTokens: 512)
        print("✅ [MLXLLMClient] AI insight generation completed")
        return response
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
                    let mlx = try Python.attemptImport("mlx.core")
                    
                    // MLX automatically uses GPU on Apple Silicon for generation
                    // No explicit device setting needed
                    
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
    
}
