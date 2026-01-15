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
