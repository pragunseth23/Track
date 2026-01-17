import Foundation

final class OnDeviceLLMClient: LLMClient {
    private static let modelDirectoryName = "phi-3.5-mini-instruct-MLX"
    
    private var mlxClient: MLXLLMClient?
    private let fallbackClient = FallbackLLMClient()
    
    init() {
        if let modelURL = Self.getModelURL() {
            mlxClient = MLXLLMClient(modelURL: modelURL)
        }
    }
    
    func generateInsight(transactionSummary: String) async throws -> String {
        if let mlxClient = mlxClient {
            do {
                return try await mlxClient.generateInsight(transactionSummary: transactionSummary)
            } catch {
                // Fallback to stub if inference fails
            }
        }
        return try await fallbackClient.generateInsight(transactionSummary: transactionSummary)
    }
    
    /// Check if the MLX model is available
    static var isModelAvailable: Bool {
        getModelURL() != nil
    }
    
    /// Get the model URL if available (checks multiple locations)
    static func getModelURL() -> URL? {
        // Check bundle resource API
        if let bundleURL = Bundle.main.url(forResource: modelDirectoryName, withExtension: nil) {
            var isDir1: ObjCBool = false
            if FileManager.default.fileExists(atPath: bundleURL.path, isDirectory: &isDir1), isDir1.boolValue {
                return bundleURL
            }
        }
        
        // Check resource path
        if let resourcePath = Bundle.main.resourcePath {
            // Check for directory
            let resourceURL = URL(fileURLWithPath: resourcePath).appendingPathComponent(modelDirectoryName)
            var isDir2: ObjCBool = false
            if FileManager.default.fileExists(atPath: resourceURL.path, isDirectory: &isDir2), isDir2.boolValue {
                return resourceURL
            }
            
            // Check if model files are directly in Resources
            let keyFiles = ["config.json", "tokenizer.json", "model.safetensors.index.json"]
            let foundKeyFiles = keyFiles.filter { file in
                FileManager.default.fileExists(atPath: URL(fileURLWithPath: resourcePath).appendingPathComponent(file).path)
            }
            
            if foundKeyFiles.count >= 2 {
                return URL(fileURLWithPath: resourcePath)
            }
        }
        
        // Check bundle Contents/Resources
        let bundleResourcesPath = (Bundle.main.bundlePath as NSString).appendingPathComponent("Contents/Resources")
        let bundleResourcesURL = URL(fileURLWithPath: bundleResourcesPath).appendingPathComponent(modelDirectoryName)
        var isDir3: ObjCBool = false
        if FileManager.default.fileExists(atPath: bundleResourcesURL.path, isDirectory: &isDir3), isDir3.boolValue {
            return bundleResourcesURL
        }
        
        // Development fallback - use source file location
        let sourceFile = (#file as NSString).deletingLastPathComponent
        let modelPathFromSource = (sourceFile as NSString).appendingPathComponent(modelDirectoryName)
        let resolvedModelPath = (modelPathFromSource as NSString).standardizingPath
        var isDir4: ObjCBool = false
        if FileManager.default.fileExists(atPath: resolvedModelPath, isDirectory: &isDir4), isDir4.boolValue {
            return URL(fileURLWithPath: resolvedModelPath)
        }
        
        return nil
    }
    
    /// Get the formatted size of the model directory
    static func getModelSize() -> String {
        guard let modelURL = getModelURL() else {
            return "~2.4 GB"
        }
        
        var totalSize: Int64 = 0
        if let enumerator = FileManager.default.enumerator(at: modelURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}
