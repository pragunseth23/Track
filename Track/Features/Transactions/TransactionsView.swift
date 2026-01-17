import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    var body: some View {
        Group {
            if transactions.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 48))
                        .foregroundColor(.textTertiary)
                    Text("NO TRANSACTIONS")
                        .font(.label)
                        .foregroundColor(.textTertiary)
                        .tracking(1.5)
                    Text("Add transactions to start tracking your spending")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(Spacing.xxxxl)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                            // Technical section header
                            HStack {
                                Text(formatDate(date))
                                    .sectionHeader()
                                Spacer()
                                Text("\(groupedTransactions[date]?.count ?? 0)")
                                    .font(.numericSmall)
                                    .foregroundColor(.textTertiary)
                            }
                            .tableRow()
                            
                            // Structured transaction rows
                            ForEach(Array((groupedTransactions[date] ?? []).enumerated()), id: \.element.id) { index, transaction in
                                TransactionRow(transaction: transaction)
                                    .tableRow()
                                    .background(index % 2 == 0 ? Color.backgroundPrimary : Color.backgroundSecondary)
                            }
                        }
                    }
                    .padding(.bottom, 80) // Space for bottom nav
                    }
                }
            }
            .background(Color.backgroundPrimary)
    }
    
    private var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date).uppercased()
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(transaction.merchantClean)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                HStack(spacing: Spacing.sm) {
                    Text(transaction.categoryNameSnapshot.uppercased())
                        .font(.labelSmall)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.surface)
                        .cornerRadius(CornerRadius.small)
                    if transaction.isSubscription {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.clockwise")
                                .font(.captionSmall)
                                .foregroundColor(.textTertiary)
                            Text("RECURRING")
                                .font(.labelSmall)
                                .foregroundColor(.textTertiary)
                        }
                        .allowsHitTesting(false)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(transaction.amountCents))
                    .font(.numeric)
                    .foregroundColor(transaction.amountCents >= 0 ? .accentSecondary : .textPrimary)
            }
        }
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

