import SwiftUI
import SwiftData
import AppKit

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    
    @State private var showResetAlert = false
    @State private var showExportSheet = false
    @State private var exportData: ExportData?
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Smart Categorization
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("SMART CATEGORIZATION")
                        .font(.label)
                        .foregroundColor(.textTertiary)
                        .tracking(1.5)
                    
                    Toggle("Smart Categorization", isOn: Binding(
                        get: { appState.smartCategorizationEnabled },
                        set: { appState.updateSmartCategorization($0) }
                    ))
                    .toggleStyle(.switch)
                    .tint(.accent)
                    
                    if appState.smartCategorizationEnabled {
                        if OnDeviceLLMClient.isModelAvailable {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.accentSecondary)
                                Text("AI model available. Transactions will use AI categorization.")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        } else {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                                Text("Model not available. Using rule-based matching only.")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
                .dataCard()
                
                // AI Model
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("AI MODEL")
                        .font(.label)
                        .foregroundColor(.textTertiary)
                        .tracking(1.5)
                    
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 24))
                            .foregroundColor(.accent)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Phi-3.5-mini-instruct")
                                .font(.bodyEmphasized)
                                .foregroundColor(.textPrimary)
                            Text("Q4 • \(OnDeviceLLMClient.getModelSize())")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color.divider)
                    
                    HStack {
                        Text("Status")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: OnDeviceLLMClient.isModelAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(OnDeviceLLMClient.isModelAvailable ? .accentSecondary : .textTertiary)
                            Text(OnDeviceLLMClient.isModelAvailable ? "Ready" : "Not Ready")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    if !OnDeviceLLMClient.isModelAvailable {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("To enable the model:")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text("1. Add 'phi-3.5-mini-instruct-MLX' to Copy Bundle Resources in Xcode")
                                .font(.captionSmall)
                                .foregroundColor(.textTertiary)
                            Text("2. Install mlx-lm: pip3 install mlx-lm")
                                .font(.captionSmall)
                                .foregroundColor(.textTertiary)
                            Button("Show Diagnostics") {
                                let (_, diagnostics) = ModelVerification.verifySetup()
                                print("📋 Model Setup Diagnostics:\n\(diagnostics)")
                            }
                            .font(.caption)
                            .foregroundColor(.accent)
                            .buttonStyle(.plain)
                            .padding(.top, Spacing.xs)
                        }
                    }
                }
                .padding(Spacing.lg)
                .dataCard()
                
                // Bank Connection
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("BANK CONNECTION")
                        .font(.label)
                        .foregroundColor(.textTertiary)
                        .tracking(1.5)
                    
                    HStack {
                        Text("Status")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.accentSecondary)
                            Text("Connected")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Divider()
                        .background(Color.divider)
                    
                    Button("Disconnect") {
                        // TODO: Implement disconnect
                    }
                    .foregroundColor(.textPrimary)
                    .buttonStyle(.bordered)
                }
                .padding(Spacing.lg)
                .dataCard()
                
                // Data
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("DATA")
                        .font(.label)
                        .foregroundColor(.textTertiary)
                        .tracking(1.5)
                    
                    VStack(spacing: Spacing.sm) {
                        Button("Generate Mock Data") {
                            Task {
                                await generateMockData()
                            }
                        }
                        .foregroundColor(.accent)
                        .buttonStyle(.bordered)
                        .tint(.accent)
                        .frame(maxWidth: .infinity)
                        
                        Button("Export All Data") {
                            exportAllData()
                        }
                        .foregroundColor(.textPrimary)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button(role: .destructive, action: {
                            showResetAlert = true
                        }) {
                            Text("Reset All Data")
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(Spacing.lg)
                .dataCard()
                
                // Privacy
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("PRIVACY")
                        .font(.label)
                        .foregroundColor(.textTertiary)
                        .tracking(1.5)
                    Text("All data is stored locally on your device. No tracking, no cloud sync, no external services.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                }
                .padding(Spacing.lg)
                .dataCard()
            }
            .padding(Spacing.lg)
            .padding(.bottom, 80) // Space for bottom nav
        }
        .background(Color.backgroundPrimary)
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
        for transaction in transactions {
            modelContext.delete(transaction)
        }
        try? modelContext.save()
    }
    
    private func generateMockData() async {
        let categoryRepository = CategoryRepository(modelContext: modelContext)
        let llmClient = appState.createLLMClient()
        let categorizationService = CategorizationService(
            llmClient: llmClient,
            categoryRepository: categoryRepository
        )
        let mockDataService = MockDataService(
            modelContext: modelContext,
            categoryRepository: categoryRepository,
            categorizationService: categorizationService
        )
        
        do {
            try await mockDataService.generateMockTransactions()
        } catch {
            print("Failed to generate mock data: \(error)")
        }
    }
}

struct ExportData: Identifiable {
    let id = UUID()
    let jsonData: String
}

struct ShareSheet: View {
    let activityItems: [Any]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("EXPORT DATA")
                    .font(.headerSmall)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            .divider()
            
            ScrollView {
                if let jsonString = activityItems.first as? String {
                    Text(jsonString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.textPrimary)
                        .textSelection(.enabled)
                        .padding(Spacing.lg)
                }
            }
            
            // Footer
            HStack {
                Button("Copy to Clipboard") {
                    if let jsonString = activityItems.first as? String {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(jsonString, forType: .string)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(Spacing.lg)
            .divider()
        }
        .background(Color.backgroundPrimary)
        .frame(width: 600, height: 500)
    }
}
