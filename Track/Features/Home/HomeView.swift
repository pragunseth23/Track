import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var budgets: [Budget]
    @Query private var insights: [Insight]
    
    @StateObject private var appState: AppState
    @State private var budgetStatus: BudgetStatus = .onTrack
    @State private var monthToDateTotal: Int = 0
    @State private var momChange: Double = 0
    @State private var categorySpending: [(name: String, value: Double, color: Color)] = []
    @State private var currentInsight: Insight?
    @State private var showCategoryDetail = false
    
    private var insightsService: InsightsService {
        let transactionRepository = TransactionRepository(modelContext: modelContext)
        let budgetRepository = BudgetRepository(modelContext: modelContext)
        let insightRepository = InsightRepository(modelContext: modelContext)
        return InsightsService(
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            insightRepository: insightRepository
        )
    }
    
    init(appState: AppState) {
        _appState = StateObject(wrappedValue: appState)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Month to Date card
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Month to Date")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Text(formatCurrency(monthToDateTotal))
                            .font(.numericXLarge)
                            .foregroundColor(.textPrimary)
                        if momChange != 0 {
                            Text("\(momChange >= 0 ? "+" : "")\(String(format: "%.0f", momChange))% vs last month")
                                .font(.caption)
                                .foregroundColor(momChange >= 0 ? .textSecondary : .destructive)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.lg)
                    .darkCard()
                    
                    // Spending by Category card
                    Button(action: {
                        showCategoryDetail = true
                    }) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Text("Spending by Category")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            if !categorySpending.isEmpty {
                                PieChartView(data: categorySpending, size: 200)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("No spending data")
                                    .font(.body)
                                    .foregroundColor(.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(Spacing.xxl)
                            }
                        }
                        .padding(Spacing.lg)
                        .darkCard()
                    }
                    
                    // Insights card
                    if let insight = currentInsight {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Insight")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Text(insight.text)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(budgetStatus.text)
                        .font(.system(size: 32, weight: .medium, design: .monospaced))
                        .foregroundColor(budgetStatus.color)
                        .textCase(.uppercase)
                        .tracking(2)
                        .shadow(color: budgetStatus.color.opacity(0.4), radius: 4)
                }
            }
            .onAppear {
                Task {
                    await loadData()
                }
            }
            .sheet(isPresented: $showCategoryDetail) {
                CategoryDetailModal(
                    data: categorySpending,
                    isPresented: $showCategoryDetail
                )
            }
        }
    }
    
    private func loadData() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        // Calculate month to date
        let monthTransactions = transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date <= endOfMonth
        }
        monthToDateTotal = monthTransactions
            .filter { $0.amountCents < 0 }
            .reduce(0) { $0 + abs($1.amountCents) }
        
        // Calculate MoM change
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? startOfMonth
        let previousMonthStart = calendar.dateInterval(of: .month, for: previousMonth)?.start ?? previousMonth
        let previousMonthEnd = calendar.dateInterval(of: .month, for: previousMonth)?.end ?? previousMonth
        
        let previousTransactions = transactions.filter { transaction in
            transaction.date >= previousMonthStart && transaction.date <= previousMonthEnd
        }
        let previousTotal = previousTransactions
            .filter { $0.amountCents < 0 }
            .reduce(0) { $0 + abs($1.amountCents) }
        
        if previousTotal > 0 {
            momChange = ((Double(monthToDateTotal) - Double(previousTotal)) / Double(previousTotal)) * 100
        }
        
        // Calculate category spending
        let categoryData = Dictionary(grouping: monthTransactions.filter { $0.amountCents < 0 }) { $0.categoryNameSnapshot }
            .mapValues { transactions in
                transactions.reduce(0) { $0 + abs($1.amountCents) }
            }
            .sorted { $0.value > $1.value }
        
        let colors: [Color] = [
            .accent,
            .statusOnTrack,
            .statusTrendingHigh,
            .destructive,
            Color(hex: "9D4EDD"), // purple
            Color(hex: "FF006E"), // pink
            Color(hex: "00D9FF"), // cyan (accent)
            Color(hex: "84FF00"), // lime
            Color(hex: "FF8500"), // orange
            Color(hex: "5A67D8")  // indigo
        ]
        categorySpending = Array(categoryData.prefix(10).enumerated().map { index, item in
            (name: item.key, value: Double(item.value), color: colors[index % colors.count])
        })
        
        // Load budget status
        do {
            budgetStatus = try await insightsService.calculateBudgetStatus(for: now)
        } catch {
            budgetStatus = .onTrack
        }
        
        // Load or generate insight
        do {
            let insightRepository = InsightRepository(modelContext: modelContext)
            if let existing = try await insightRepository.fetchForMonth(now) {
                currentInsight = existing
            } else {
                currentInsight = try await insightsService.generateInsight(
                    for: now,
                    smartCategorizationEnabled: appState.smartCategorizationEnabled
                )
            }
        } catch {
            // Handle error
        }
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

struct CategoryDetailModal: View {
    let data: [(name: String, value: Double, color: Color)]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    PieChartView(data: data, size: 250)
                        .padding(.top, Spacing.xl)
                    
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ForEach(data, id: \.name) { item in
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(formatCurrency(item.value))
                                        .font(.numeric)
                                        .foregroundColor(.textPrimary)
                                    Text("\(String(format: "%.0f", (item.value / data.reduce(0.0) { $0 + $1.value }) * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .padding(.vertical, Spacing.sm)
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Spending by Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.accent)
                }
            }
        }
    }
    
    private func formatCurrency(_ cents: Double) -> String {
        let dollars = cents / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}
