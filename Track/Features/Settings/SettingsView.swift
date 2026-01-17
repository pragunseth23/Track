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
                // AI Model - Full width
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("AI MODEL")
                        .sectionHeader()
                    
                    HStack(alignment: .top, spacing: Spacing.md) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 28))
                            .foregroundColor(.accent)
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(spacing: Spacing.md) {
                                Text("Phi-3.5-mini-instruct")
                                    .font(.bodyEmphasized)
                                    .foregroundColor(.textPrimary)
                                
                                if OnDeviceLLMClient.isModelAvailable {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.accentSecondary)
                                            .frame(width: 8, height: 8)
                                        Text("Ready")
                                            .font(.bodySmall)
                                            .foregroundColor(.accentSecondary)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 4)
                                    .background(Color.accentSecondary.opacity(0.15))
                                    .cornerRadius(CornerRadius.small)
                                }
                            }
                            Text("Q4 • \(OnDeviceLLMClient.getModelSize())")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
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
                                let (_, diagnostics) = ModelVerificationService.verifySetup()
                                print("📋 Model Setup Diagnostics:\n\(diagnostics)")
                            }
                            .font(.caption)
                            .foregroundColor(.accent)
                            .buttonStyle(.plain)
                            .padding(.top, Spacing.xs)
                        }
                        .padding(.top, Spacing.sm)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 160)
                .padding(Spacing.lg)
                .dataCard()
                
                // Bank Connection and Data - Side by side
                HStack(alignment: .top, spacing: Spacing.lg) {
                    // Bank Connection
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("BANK CONNECTION")
                            .sectionHeader()
                        
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.accent)
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                HStack(spacing: Spacing.md) {
                                    Text("Primary Account")
                                        .font(.bodyEmphasized)
                                        .foregroundColor(.textPrimary)
                                    
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.accentSecondary)
                                            .frame(width: 8, height: 8)
                                        Text("Connected")
                                            .font(.bodySmall)
                                            .foregroundColor(.accentSecondary)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 4)
                                    .background(Color.accentSecondary.opacity(0.15))
                                    .cornerRadius(CornerRadius.small)
                                }
                                Text("Last synced: Today")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                        }
                        
                        Button("Disconnect") {
                            // TODO: Implement disconnect
                        }
                        .foregroundColor(.textPrimary)
                        .buttonStyle(.bordered)
                        .padding(.top, Spacing.sm)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 160)
                    .padding(Spacing.lg)
                    .dataCard()
                    
                    // Data
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("DATA")
                            .sectionHeader()
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Button("Generate Mock Data") {
                                Task {
                                    await generateMockData()
                                }
                            }
                            .foregroundColor(.accent)
                            .buttonStyle(.bordered)
                            .tint(.accent)
                            
                            Button("Export All Data") {
                                exportAllData()
                            }
                            .foregroundColor(.textPrimary)
                            .buttonStyle(.bordered)
                            
                            Button(role: .destructive, action: {
                                showResetAlert = true
                            }) {
                                Text("Reset All Data")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 160)
                    .padding(Spacing.lg)
                    .dataCard()
                }
                
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
                Text("This will delete all transactions and categories. This action cannot be undone.")
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
        let categorizationService = CategorizationService(
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
