import Foundation

/// Helper to verify model setup and provide diagnostic information
enum ModelVerification {
    static func verifySetup() -> (isAvailable: Bool, diagnostics: String) {
        var diagnostics: [String] = []
        var isAvailable = false
        
        // Check 1: Model directory in bundle
        let modelDirName = "phi-3.5-mini-instruct-MLX"
        if let bundleURL = Bundle.main.url(forResource: modelDirName, withExtension: nil) {
            diagnostics.append("✅ Model directory found in bundle: \(bundleURL.path)")
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: bundleURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                isAvailable = true
            } else {
                diagnostics.append("❌ Bundle path exists but is not a directory")
            }
        } else {
            diagnostics.append("❌ Model directory not found in bundle")
            
            // Check resource path
            if let resourcePath = Bundle.main.resourcePath {
                let resourceURL = URL(fileURLWithPath: resourcePath).appendingPathComponent(modelDirName)
                if FileManager.default.fileExists(atPath: resourceURL.path) {
                    diagnostics.append("⚠️ Found in resource path (development): \(resourceURL.path)")
                    isAvailable = true
                }
            }
        }
        
        // Check 2: Required files
        if let modelURL = OnDeviceLLMClient.getModelURL() {
            let requiredFiles = ["config.json", "tokenizer.json", "model.safetensors.index.json"]
            for fileName in requiredFiles {
                let filePath = (modelURL.path as NSString).appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: filePath) {
                    diagnostics.append("✅ Found: \(fileName)")
                } else {
                    diagnostics.append("❌ Missing: \(fileName)")
                    isAvailable = false
                }
            }
            
            // Check safetensors files
            let safetensorsPattern = "model-.*\\.safetensors"
            if let enumerator = FileManager.default.enumerator(at: modelURL, includingPropertiesForKeys: nil) {
                var foundSafetensors = false
                for case let fileURL as URL in enumerator {
                    if fileURL.lastPathComponent.range(of: safetensorsPattern, options: .regularExpression) != nil {
                        foundSafetensors = true
                        break
                    }
                }
                if foundSafetensors {
                    diagnostics.append("✅ Found safetensors model files")
                } else {
                    diagnostics.append("❌ Missing safetensors model files")
                    isAvailable = false
                }
            }
        }
        
        // Check 3: Python environment (informational)
        diagnostics.append("\nPython Environment:")
        if let pythonPath = runCommand("which python3") {
            diagnostics.append("✅ Python3 found: \(pythonPath)")
        } else {
            diagnostics.append("⚠️ Python3 not found in PATH")
        }
        
        // Check 4: mlx-lm package (informational)
        if let mlxCheck = runCommand("python3 -c 'import mlx_lm; print(\"installed\")' 2>&1"), mlxCheck.contains("installed") {
            diagnostics.append("✅ mlx-lm package is installed")
        } else {
            diagnostics.append("⚠️ mlx-lm package not found. Install with: pip3 install mlx-lm")
        }
        
        return (isAvailable, diagnostics.joined(separator: "\n"))
    }
    
    private static func runCommand(_ command: String) -> String? {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
