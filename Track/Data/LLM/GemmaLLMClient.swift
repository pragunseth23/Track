import Foundation
import CoreML

/// Client for running Gemma 2 2B Instruct model inference
/// 
/// IMPORTANT: The model downloaded from Hugging Face is in PyTorch/safetensors format,
/// which is not directly usable on iOS. You have two options:
///
/// Option 1: Convert to CoreML
/// - Use coremltools to convert the Hugging Face model to CoreML format
/// - Place the .mlmodelc bundle in the model directory
/// - Update the model loading code below to use MLModel
///
/// Option 2: Use quantized GGUF version
/// - Download a GGUF quantized version (e.g., from TheBloke on Hugging Face)
/// - Use llama.cpp or similar runtime for inference
///
/// For now, this implementation provides a framework that can be adapted once
/// you have a CoreML-converted model or GGUF runtime integrated.
final class GemmaLLMClient: LLMClient {
    private let modelURL: URL
    private var model: MLModel?
    private let maxSequenceLength = 512
    
    init(modelURL: URL) {
        self.modelURL = modelURL
    }
    
    private func loadCoreMLModel() throws {
        // Look for .mlmodelc bundle in the model directory
        let modelcURL = modelURL.appendingPathComponent("model.mlmodelc")
        if FileManager.default.fileExists(atPath: modelcURL.path) {
            let modelConfig = MLModelConfiguration()
            modelConfig.computeUnits = .cpuAndNeuralEngine
            model = try MLModel(contentsOf: modelcURL, configuration: modelConfig)
        } else {
            throw LLMError.modelLoadFailed("CoreML model not found. Please convert the Hugging Face model to CoreML format.")
        }
    }
    
    func categorize(merchant: String, amount: Int, existingCategories: [String]) async throws -> String {
        // Load model if not already loaded
        if model == nil {
            do {
                try loadCoreMLModel()
            } catch {
                // If CoreML model not available, fall back to a simple rule-based approach
                // In production, you'd want to use a quantized GGUF model with llama.cpp
                throw LLMError.modelLoadFailed("Model not available in CoreML format. Please convert the Hugging Face model or use a quantized GGUF version.")
            }
        }
        
        guard let model = model else {
            throw LLMError.modelNotLoaded
        }
        
        // Create prompt for categorization
        let categoriesList = existingCategories.joined(separator: ", ")
        let prompt = """
        You are a financial transaction categorization assistant. 
        Categorize the following transaction into one of these categories: \(categoriesList)
        
        Merchant: \(merchant)
        Amount: $\(String(format: "%.2f", Double(abs(amount)) / 100.0))
        
        Respond with only a JSON object in this format:
        {"category": "CategoryName"}
        
        Choose the most appropriate category from the list provided.
        """
        
        // For CoreML text generation models, we need to use the model's prediction method
        // This is a simplified version - actual implementation depends on the model's input/output format
        do {
            let input = try createModelInput(from: prompt)
            let prediction = try model.prediction(from: input)
            let output = try extractOutput(from: prediction)
            
            // Parse JSON response
            if let category = JSONGuard.extractCategory(from: output) {
                return category
            } else {
                // Fallback: try to extract category name directly if JSON parsing fails
                return extractCategoryFromText(output, categories: existingCategories)
            }
        } catch {
            throw LLMError.inferenceFailed(error.localizedDescription)
        }
    }
    
    private func createModelInput(from prompt: String) throws -> MLFeatureProvider {
        // Convert prompt to model input format
        // This depends on the specific CoreML model structure
        // For Gemma models, typically we need tokenized input
        
        // Simplified: Create a feature dictionary
        // In practice, you'd need to tokenize the input using the model's tokenizer
        let inputFeatures: [String: MLFeatureValue] = [
            "input_ids": MLFeatureValue(multiArray: tokenizeText(prompt)),
            "attention_mask": MLFeatureValue(multiArray: createAttentionMask(for: prompt))
        ]
        
        return try MLDictionaryFeatureProvider(dictionary: inputFeatures)
    }
    
    private func tokenizeText(_ text: String) -> MLMultiArray {
        // IMPORTANT: This is a simplified tokenization placeholder
        // 
        // For actual Gemma 2 models, you need to use the model's tokenizer:
        // 1. Gemma uses SentencePiece tokenization
        // 2. You'll need to include the tokenizer (usually tokenizer.json) with your model
        // 3. Use a Swift tokenizer library or implement SentencePiece tokenization
        //
        // For now, this creates a basic encoding that may work for testing but
        // will not produce accurate results without proper tokenization.
        
        let bytes = Array(text.utf8)
        let length = min(bytes.count, maxSequenceLength)
        
        guard let array = try? MLMultiArray(shape: [1, NSNumber(value: length)], dataType: .int32) else {
            // Fallback: return minimal array
            return try! MLMultiArray(shape: [1, 1], dataType: .int32)
        }
        
        for (index, byte) in bytes.prefix(maxSequenceLength).enumerated() {
            array[index] = NSNumber(value: Int32(byte))
        }
        
        // Pad remaining positions if needed
        for index in bytes.count..<maxSequenceLength {
            array[index] = NSNumber(value: 0) // Padding token
        }
        
        return array
    }
    
    private func createAttentionMask(for text: String) -> MLMultiArray {
        let length = min(text.utf8.count, maxSequenceLength)
        guard let array = try? MLMultiArray(shape: [1, NSNumber(value: maxSequenceLength)], dataType: .int32) else {
            return try! MLMultiArray(shape: [1, 1], dataType: .int32)
        }
        
        // Set 1 for actual tokens, 0 for padding
        for i in 0..<length {
            array[i] = NSNumber(value: 1)
        }
        for i in length..<maxSequenceLength {
            array[i] = NSNumber(value: 0)
        }
        
        return array
    }
    
    private func extractOutput(from prediction: MLFeatureProvider) throws -> String {
        // Extract text output from model prediction
        // This depends on the model's output format
        
        // Try common output feature names
        let possibleOutputKeys = ["output", "logits", "generated_text", "text"]
        
        for key in possibleOutputKeys {
            if let feature = prediction.featureValue(for: key) {
                // Check if feature is a string type
                if feature.type == .string {
                    let stringValue = feature.stringValue
                    if !stringValue.isEmpty {
                        return stringValue
                    }
                }
                
                // Check for multiArray output
                if feature.type == .multiArray, let multiArray = feature.multiArrayValue {
                    // Decode from multi-array (detokenize)
                    return detokenize(multiArray)
                }
            }
        }
        
        // Fallback: return empty string
        return ""
    }
    
    private func detokenize(_ array: MLMultiArray) -> String {
        // Simplified detokenization
        // In practice, use the model's actual tokenizer
        var bytes: [UInt8] = []
        for i in 0..<array.count {
            let value = array[i].int32Value
            if value > 0 && value < 256 {
                bytes.append(UInt8(value))
            }
        }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }
    
    private func extractCategoryFromText(_ text: String, categories: [String]) -> String {
        // Fallback: try to find a category name in the text
        let lowercased = text.lowercased()
        for category in categories {
            if lowercased.contains(category.lowercased()) {
                return category
            }
        }
        return "Other"
    }
}

enum LLMError: LocalizedError {
    case modelLoadFailed(String)
    case modelNotLoaded
    case inferenceFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let message):
            return "Failed to load model: \(message)"
        case .modelNotLoaded:
            return "Model is not loaded"
        case .inferenceFailed(let message):
            return "Inference failed: \(message)"
        }
    }
}
