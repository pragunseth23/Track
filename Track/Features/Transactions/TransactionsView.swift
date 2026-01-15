import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var categories: [Category]
    
    @State private var selectedTransaction: Transaction?
    @State private var showEditSheet = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(formatDate(date))) {
                        ForEach(groupedTransactions[date] ?? []) { transaction in
                            TransactionRow(transaction: transaction)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTransaction = transaction
                                    showEditSheet = true
                                }
                        }
                    }
                }
            }
            .background(Color.backgroundPrimary)
            .scrollContentBackground(.hidden)
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEditSheet) {
                if let transaction = selectedTransaction {
                    EditTransactionSheet(
                        transaction: transaction,
                        categories: categories,
                        isPresented: $showEditSheet
                    )
                }
            }
        }
    }
    
    private var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchantClean)
                    .font(.bodyEmphasized)
                    .foregroundColor(.textPrimary)
                HStack(spacing: 4) {
                    Text(transaction.categoryNameSnapshot)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    if transaction.isSubscription {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            Spacer()
            Text(formatCurrency(transaction.amountCents))
                .font(.numeric)
                .foregroundColor(transaction.amountCents >= 0 ? .accent : .textPrimary)
        }
        .padding(.vertical, Spacing.xs)
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let dollars = Double(abs(cents)) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let formatted = formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
        return transaction.amountCents >= 0 ? "+\(formatted)" : formatted
    }
}

struct EditTransactionSheet: View {
    @Bindable var transaction: Transaction
    let categories: [Category]
    @Binding var isPresented: Bool
    
    @State private var selectedCategoryId: UUID
    @State private var note: String
    @State private var isSubscription: Bool
    
    @Environment(\.modelContext) private var modelContext
    
    init(transaction: Transaction, categories: [Category], isPresented: Binding<Bool>) {
        self.transaction = transaction
        self.categories = categories
        _isPresented = isPresented
        _selectedCategoryId = State(initialValue: transaction.categoryId)
        _note = State(initialValue: transaction.note ?? "")
        _isSubscription = State(initialValue: transaction.isSubscription)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Menu {
                        ForEach(categories) { category in
                            Button(category.name) {
                                selectedCategoryId = category.id
                            }
                        }
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(categories.first(where: { $0.id == selectedCategoryId })?.name ?? "Unknown")
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                Section("Details") {
                    Toggle("Subscription", isOn: $isSubscription)
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .background(Color.backgroundPrimary)
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .foregroundColor(.accent)
                }
            }
        }
    }
    
    private func saveTransaction() {
        if let category = categories.first(where: { $0.id == selectedCategoryId }) {
            transaction.categoryId = category.id
            transaction.categoryNameSnapshot = category.name
        }
        transaction.note = note.isEmpty ? nil : note
        transaction.isSubscription = isSubscription
        
        try? modelContext.save()
        isPresented = false
    }
}
