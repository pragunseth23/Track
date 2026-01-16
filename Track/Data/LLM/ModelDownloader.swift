import Foundation
import Combine

/// Model Download State
///
/// Tracks the current state of the Gemma 2 2B Instruct model download
enum ModelDownloadState {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case error(String)
}

/// Model Downloader for Gemma 2 2B Instruct from Hugging Face
///
/// This downloader fetches the model files from Hugging Face (google/gemma-2-2b-it).
/// The downloaded model is in PyTorch/safetensors format, which needs to be converted
/// to CoreML format for iOS use.
///
/// **Model Conversion Required:**
/// The Hugging Face model cannot be used directly on iOS. You need to:
///
/// 1. **Convert to CoreML** (Recommended for iOS):
///    ```python
///    import coremltools as ct
///    from transformers import AutoModelForCausalLM, AutoTokenizer
///
///    model_id = "google/gemma-2-2b-it"
///    tokenizer = AutoTokenizer.from_pretrained(model_id)
///    model = AutoModelForCausalLM.from_pretrained(model_id)
///
///    # Convert to CoreML
///    mlmodel = ct.convert(model, source="pytorch")
///    mlmodel.save("gemma-2-2b-it.mlmodelc")
///    ```
///
/// 2. **Or use a quantized GGUF version** with llama.cpp:
///    - Download from TheBloke or similar quantized model repositories
///    - Integrate llama.cpp Swift bindings
///    - Use the GGUF model file directly
///
/// 3. **Or use ONNX Runtime**:
///    - Convert model to ONNX format
///    - Use ONNX Runtime for iOS
///
/// Once converted, place the CoreML model (.mlmodelc) in the model directory
/// and update GemmaLLMClient to load it.

@MainActor
final class ModelDownloader: ObservableObject {
    @Published var downloadState: ModelDownloadState = .notDownloaded
    
    private let modelRepo = "google/gemma-2-2b-it"
    private let modelName = "gemma-2-2b-it"
    private var downloadTask: URLSessionDownloadTask?
    
    // Hugging Face token for gated models (optional, set via UserDefaults or Settings)
    private var huggingFaceToken: String? {
        UserDefaults.standard.string(forKey: "huggingFaceToken")
    }
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var modelDirectory: URL {
        documentsDirectory.appendingPathComponent("Models", isDirectory: true)
            .appendingPathComponent(modelName, isDirectory: true)
    }
    
    private var modelURL: URL {
        modelDirectory
    }
    
    // Required files for the model
    private let requiredFiles = [
        "config.json",
        "tokenizer_config.json",
        "tokenizer.json",
        "model.safetensors.index.json"
    ]
    
    var isModelAvailable: Bool {
        // Check if all required files exist
        let allFilesExist = requiredFiles.allSatisfy { fileName in
            let fileURL = modelDirectory.appendingPathComponent(fileName)
            return FileManager.default.fileExists(atPath: fileURL.path)
        }
        return allFilesExist && FileManager.default.fileExists(atPath: modelDirectory.path)
    }
    
    init() {
        checkModelStatus()
    }
    
    func checkModelStatus() {
        if isModelAvailable {
            downloadState = .downloaded
        } else {
            downloadState = .notDownloaded
        }
    }
    
    func downloadModel() async {
        guard case .notDownloaded = downloadState else { return }
        
        // Check if token is available (required for gated models)
        if huggingFaceToken == nil || huggingFaceToken?.isEmpty == true {
            downloadState = .error("Hugging Face token is required. This model is gated - you must:\n1. Accept the model terms at huggingface.co/google/gemma-2-2b-it\n2. Get your token from huggingface.co/settings/tokens\n3. Enter it in Settings above")
            return
        }
        
        // Validate token format (should start with "hf_")
        if let token = huggingFaceToken, !token.hasPrefix("hf_") {
            downloadState = .error("Invalid token format. Hugging Face tokens should start with 'hf_'. Please check your token.")
            return
        }
        
        downloadState = .downloading(progress: 0.0)
        
        do {
            // Create model directory if it doesn't exist
            try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
            
            // Download required files from Hugging Face
            // Note: This model is gated, so you need a Hugging Face token
            // Get your token from https://huggingface.co/settings/tokens
            
            var totalProgress: Double = 0.0
            let totalFiles = requiredFiles.count + 1 // +1 for model weights
            
            // Download config and tokenizer files
            for (index, fileName) in requiredFiles.enumerated() {
                let fileURL = try await downloadFile(
                    fileName: fileName,
                    progress: { fileProgress in
                        Task { @MainActor in
                            // Calculate overall progress
                            let fileWeight = 1.0 / Double(totalFiles)
                            totalProgress = (Double(index) / Double(totalFiles)) + (fileProgress * fileWeight)
                            self.downloadState = .downloading(progress: totalProgress)
                        }
                    }
                )
                
                // Move to model directory
                let destination = modelDirectory.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: fileURL, to: destination)
            }
            
            // Download model weights (safetensors files)
            // First, check the model index to see which weight files we need
            let indexFile = modelDirectory.appendingPathComponent("model.safetensors.index.json")
            if FileManager.default.fileExists(atPath: indexFile.path),
               let indexData = try? Data(contentsOf: indexFile),
               let indexJSON = try? JSONSerialization.jsonObject(with: indexData) as? [String: Any],
               let weightMap = indexJSON["weight_map"] as? [String: String] {
                
                // Get unique weight files
                let weightFiles = Set(weightMap.values)
                let totalWeights = weightFiles.count
                
                for (index, weightFile) in weightFiles.enumerated() {
                    let fileURL = try await downloadFile(
                        fileName: weightFile,
                        progress: { fileProgress in
                            Task { @MainActor in
                                let configWeight = Double(requiredFiles.count) / Double(totalFiles)
                                let weightProgress = (Double(index) / Double(totalWeights)) + (fileProgress / Double(totalWeights))
                                totalProgress = configWeight + (weightProgress * (1.0 - configWeight))
                                self.downloadState = .downloading(progress: totalProgress)
                            }
                        }
                    )
                    
                    let destination = modelDirectory.appendingPathComponent(weightFile)
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.moveItem(at: fileURL, to: destination)
                }
            } else {
                // Fallback: try downloading single model file
                let fileURL = try await downloadFile(
                    fileName: "model.safetensors",
                    progress: { fileProgress in
                        Task { @MainActor in
                            let configWeight = Double(requiredFiles.count) / Double(totalFiles)
                            totalProgress = configWeight + (fileProgress * (1.0 - configWeight))
                            self.downloadState = .downloading(progress: totalProgress)
                        }
                    }
                )
                
                let destination = modelDirectory.appendingPathComponent("model.safetensors")
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: fileURL, to: destination)
            }
            
            downloadState = .downloaded
        } catch {
            downloadState = .error("Failed to download model: \(error.localizedDescription)")
        }
    }
    
    private func downloadFile(fileName: String, progress: @escaping (Double) -> Void) async throws -> URL {
        // Construct Hugging Face CDN URL
        // Format: https://huggingface.co/{repo}/resolve/main/{filename}
        let baseURL = "https://huggingface.co/\(modelRepo)/resolve/main/\(fileName)"
        
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "ModelDownloader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for file: \(fileName)"])
        }
        
        var request = URLRequest(url: url)
        
        // Add authentication header if token is available
        if let token = huggingFaceToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (tempURL, response) = try await URLSession.shared.download(from: request) { downloadProgress in
            progress(downloadProgress.fractionCompleted)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ModelDownloader", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // Handle authentication and authorization errors
        if httpResponse.statusCode == 401 {
            throw NSError(domain: "ModelDownloader", code: 3, userInfo: [NSLocalizedDescriptionKey: "Authentication failed. Please check your Hugging Face token in Settings."])
        }
        
        if httpResponse.statusCode == 403 {
            throw NSError(domain: "ModelDownloader", code: 5, userInfo: [NSLocalizedDescriptionKey: "Access denied. You must accept the model terms at huggingface.co/google/gemma-2-2b-it before downloading. Make sure you're logged in and have accepted the terms."])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg: String
            if httpResponse.statusCode == 404 {
                errorMsg = "File not found: \(fileName). The model structure may have changed."
            } else {
                errorMsg = "Failed to download \(fileName): HTTP \(httpResponse.statusCode)"
            }
            throw NSError(domain: "ModelDownloader", code: 4, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        return tempURL
    }
    
    
    func deleteModel() {
        guard isModelAvailable else { return }
        
        try? FileManager.default.removeItem(at: modelURL)
        downloadState = .notDownloaded
    }
    
    func reloadModel() {
        checkModelStatus()
    }
    
    func getModelURL() -> URL? {
        guard isModelAvailable else { return nil }
        return modelURL
    }
    
    func setHuggingFaceToken(_ token: String) {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmedToken, forKey: "huggingFaceToken")
    }
    
    func hasValidToken() -> Bool {
        guard let token = huggingFaceToken, !token.isEmpty else {
            return false
        }
        // Hugging Face tokens typically start with "hf_"
        return token.hasPrefix("hf_")
    }
    
    func getHuggingFaceModelURL() -> URL? {
        return URL(string: "https://huggingface.co/\(modelRepo)")
    }
    
    func getHuggingFaceTokenURL() -> URL? {
        return URL(string: "https://huggingface.co/settings/tokens")
    }
    
    func getModelSize() -> String {
        // Calculate total size of model files
        guard isModelAvailable else { return "~2.5 GB" }
        
        var totalSize: Int64 = 0
        let fileManager = FileManager.default
        
        if let enumerator = fileManager.enumerator(at: modelURL, includingPropertiesForKeys: [.fileSizeKey]) {
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

extension URLSession {
    func download(from request: URLRequest, progress: @escaping (Double) -> Void) async throws -> (URL, URLResponse) {
        let (asyncBytes, response) = try await self.bytes(for: request)
        
        let fileName = request.url?.lastPathComponent ?? "download"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(fileName)
        
        // Create parent directory
        try? FileManager.default.createDirectory(at: tempURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let fileHandle = try FileHandle(forWritingTo: tempURL)
        defer { try? fileHandle.close() }
        
        var totalBytes: Int64 = 0
        let expectedBytes = response.expectedContentLength
        
        for try await byte in asyncBytes {
            try fileHandle.write(contentsOf: [byte])
            totalBytes += 1
            
            if expectedBytes > 0 {
                let progressValue = Double(totalBytes) / Double(expectedBytes)
                progress(progressValue)
            } else {
                // If we don't know the total, just report incremental progress
                progress(0.5) // Placeholder
            }
        }
        
        return (tempURL, response)
    }
}
