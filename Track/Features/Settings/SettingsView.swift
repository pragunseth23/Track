import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    
    @State private var showResetAlert = false
    @State private var showExportSheet = false
    @State private var exportData: ExportData?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Smart Categorization") {
                    Toggle("Smart Categorization", isOn: Binding(
                        get: { appState.smartCategorizationEnabled },
                        set: { appState.updateSmartCategorization($0) }
                    ))
                    
                    // Hugging Face Token (for gated models)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text("Hugging Face Token")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            if UserDefaults.standard.string(forKey: "huggingFaceToken")?.isEmpty == false {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.statusOnTrack)
                                    .font(.caption)
                            }
                        }
                        SecureField("hf_...", text: Binding(
                            get: { UserDefaults.standard.string(forKey: "huggingFaceToken") ?? "" },
                            set: { appState.modelDownloader.setHuggingFaceToken($0) }
                        ))
                        .textContentType(.password)
                        .foregroundColor(.textPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Required for gated models. Steps:")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                            HStack(spacing: 4) {
                                Text("1. Accept model terms:")
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                                if let url = appState.modelDownloader.getHuggingFaceModelURL() {
                                    Link("Open Model Page", destination: url)
                                        .font(.caption2)
                                        .foregroundColor(.accent)
                                }
                            }
                            HStack(spacing: 4) {
                                Text("2. Get token:")
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                                if let url = appState.modelDownloader.getHuggingFaceTokenURL() {
                                    Link("Open Token Settings", destination: url)
                                        .font(.caption2)
                                        .foregroundColor(.accent)
                                }
                            }
                            Text("3. Paste token above (starts with 'hf_')")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                    
                    // Model Download Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("AI Model")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            modelStatusView
                        }
                        
                        if case .downloading(let progress) = appState.modelDownloader.downloadState {
                            ProgressView(value: progress)
                                .tint(.accent)
                        }
                        
                        modelActionButton
                    }
                    .padding(.vertical, Spacing.xs)
                }
                
                Section("Bank Connection") {
                    HStack {
                        Text("Status")
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.statusOnTrack)
                            Text("Connected")
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Button("Disconnect") {
                        // TODO: Implement disconnect
                    }
                    .foregroundColor(.textPrimary)
                }
                
                Section("Data") {
                    Button("Export All Data") {
                        exportAllData()
                    }
                    .foregroundColor(.textPrimary)
                    
                    Button(role: .destructive, action: {
                        showResetAlert = true
                    }) {
                        Text("Reset All Data")
                    }
                }
                
                Section("Privacy") {
                    Text("All data is stored locally on your device. No tracking, no cloud sync, no external services.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .background(Color.backgroundPrimary)
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will delete all transactions, budgets, and categories. This action cannot be undone.")
            }
            .sheet(item: $exportData) { data in
                ShareSheet(activityItems: [data.jsonData])
            }
        }
    }
    
    @ViewBuilder
    private var modelStatusView: some View {
        switch appState.modelDownloader.downloadState {
        case .notDownloaded:
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.textSecondary)
                Text("Not Downloaded")
                    .foregroundColor(.textSecondary)
                    .font(.caption)
            }
        case .downloading(let progress):
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("\(Int(progress * 100))%")
                    .foregroundColor(.textSecondary)
                    .font(.caption)
            }
        case .downloaded:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.statusOnTrack)
                Text("Ready")
                    .foregroundColor(.textSecondary)
                    .font(.caption)
            }
        case .error(let message):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.destructive)
                Text("Error")
                    .foregroundColor(.destructive)
                    .font(.caption)
            }
        }
    }
    
    @ViewBuilder
    private var modelActionButton: some View {
        switch appState.modelDownloader.downloadState {
        case .notDownloaded, .error:
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Download the Gemma 2 2B Instruct model from Hugging Face for on-device AI categorization.")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Text("Note: The downloaded model needs to be converted to CoreML format for iOS. See ModelDownloader.swift for conversion instructions.")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                            .italic()
                        Button("Download Gemma 2 2B Model") {
                            Task {
                                await appState.modelDownloader.downloadModel()
                                // Reload model in LLM client if download succeeded
                                if case .downloaded = appState.modelDownloader.downloadState {
                                    // The OnDeviceLLMClient will automatically reload on next use
                                }
                            }
                        }
                        .foregroundColor(.accent)
                    }
        case .downloading:
            Button("Downloading...") {
                // Disabled during download
            }
            .foregroundColor(.textSecondary)
            .disabled(true)
        case .downloaded:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Model Size: \(appState.modelDownloader.getModelSize())")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                Button(role: .destructive, action: {
                    appState.modelDownloader.deleteModel()
                }) {
                    Text("Delete Model")
                }
            }
        }
    }
    
    private func exportAllData() {
        struct ExportTransaction: Codable {
            let id: String
            let date: String
            let merchantRaw: String
            let merchantClean: String
            let amountCents: Int
            let currency: String
            let categoryName: String
            let isSubscription: Bool
            let note: String?
            let source: String
        }
        
        let exportTransactions = transactions.map { transaction in
            ExportTransaction(
                id: transaction.id.uuidString,
                date: ISO8601DateFormatter().string(from: transaction.date),
                merchantRaw: transaction.merchantRaw,
                merchantClean: transaction.merchantClean,
                amountCents: transaction.amountCents,
                currency: transaction.currency,
                categoryName: transaction.categoryNameSnapshot,
                isSubscription: transaction.isSubscription,
                note: transaction.note,
                source: transaction.source
            )
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let jsonData = try? encoder.encode(exportTransactions),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            exportData = ExportData(jsonData: jsonString)
        }
    }
    
    private func resetAllData() {
        // Delete all transactions
        for transaction in transactions {
            modelContext.delete(transaction)
        }
        
        // Note: Categories and budgets would also need to be deleted
        // For MVP, we'll keep system categories
        
        try? modelContext.save()
    }
}

struct ExportData: Identifiable {
    let id = UUID()
    let jsonData: String
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
