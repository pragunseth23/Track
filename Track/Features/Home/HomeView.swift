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
    @State private var isGeneratingInsight = false
    
    private var insightsService: InsightsService {
        let transactionRepository = TransactionRepository(modelContext: modelContext)
        let budgetRepository = BudgetRepository(modelContext: modelContext)
        let insightRepository = InsightRepository(modelContext: modelContext)
        let llmClient = appState.createLLMClient()
        return InsightsService(
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            insightRepository: insightRepository,
            llmClient: llmClient
        )
    }
    
    init(appState: AppState) {
        _appState = StateObject(wrappedValue: appState)
    }
    
    var body: some View {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                // Header with budget status - Full width card
                HStack(alignment: .top, spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("MONTH TO DATE")
                            .font(.label)
                            .foregroundColor(.textTertiary)
                            .tracking(1.5)
                        Text(formatCurrency(monthToDateTotal))
                            .font(.numericXLarge)
                            .foregroundColor(.textPrimary)
                        if momChange != 0 {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: momChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.captionSmall)
                                    .foregroundColor(momChange >= 0 ? .textSecondary : .accentError)
                                Text("\(String(format: "%.1f", abs(momChange)))% vs last month")
                                .font(.caption)
                                    .foregroundColor(momChange >= 0 ? .textSecondary : .accentError)
                            }
                            .padding(.top, Spacing.xs)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: Spacing.sm) {
                        Text("STATUS")
                            .font(.label)
                            .foregroundColor(.textTertiary)
                            .tracking(1.5)
                        Text(budgetStatus.text)
                            .font(.numericLarge)
                            .foregroundColor(budgetStatus.color)
                            .tracking(3)
                    }
                }
                .dataCard()
                
                // Grid layout for data cards - Equal height
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg)
                ], spacing: Spacing.lg) {
                    // Spending by Category
                    Button(action: {
                        showCategoryDetail = true
                    }) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Text("SPENDING BY CATEGORY")
                                    .font(.label)
                                    .foregroundColor(.textTertiary)
                                    .tracking(1.5)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                            
                            if !categorySpending.isEmpty {
                                PieChartView(data: categorySpending, size: 180)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm)
                                
                                // Top 3 categories
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    ForEach(Array(categorySpending.prefix(3).enumerated()), id: \.offset) { index, item in
                                        HStack(spacing: Spacing.sm) {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 10, height: 10)
                                            Text(item.name)
                                                .font(.bodySmall)
                                                .foregroundColor(.textSecondary)
                                            Spacer()
                                            Text(formatCurrency(item.value))
                                                .font(.numericSmall)
                                                .foregroundColor(.textPrimary)
                                        }
                                    }
                                }
                                .padding(.top, Spacing.xs)
                            } else {
                                VStack(spacing: Spacing.sm) {
                                    Image(systemName: "chart.pie.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.textTertiary)
                                Text("No spending data")
                                        .font(.bodySmall)
                                        .foregroundColor(.textTertiary)
                                }
                                    .frame(maxWidth: .infinity)
                                    .padding(Spacing.xxl)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: CardDimensions.standardHeight, alignment: .top)
                    }
                    .buttonStyle(.plain)
                    .dataCard()
                    
                    // Insights card - Equal height
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("AI INSIGHT")
                                .font(.label)
                                .foregroundColor(.textTertiary)
                                .tracking(1.5)
                            Spacer()
                            Button(action: {
                                Task {
                                    isGeneratingInsight = true
                                    await generateInsight()
                                    isGeneratingInsight = false
                                }
                            }) {
                                if isGeneratingInsight {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.accent)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                        .foregroundColor(.accent)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isGeneratingInsight)
                        }
                        
                    if let insight = currentInsight {
                            Text(insight.text)
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Tap refresh to generate insights based on your transactions.")
                                    .font(.bodySmall)
                                    .foregroundColor(.textTertiary)
                                    .lineSpacing(6)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: CardDimensions.standardHeight, alignment: .top)
                    .dataCard()
                }
            }
            .padding(Spacing.lg)
            .padding(.bottom, 80) // Space for bottom nav
        }
        .background(Color.backgroundPrimary)
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
            .accentSecondary,
            .accentWarning,
            .accentError,
            Color(hex: "9D4EDD"), // purple
            Color(hex: "FF006E"), // pink
            Color(hex: "00D9FF"), // cyan
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
        
        // Load existing insight if available
        do {
            let insightRepository = InsightRepository(modelContext: modelContext)
            if let existing = try await insightRepository.fetchForMonth(now) {
                currentInsight = existing
            }
        } catch {
            print("❌ [HomeView] Failed to load insight: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func generateInsight() async {
        let calendar = Calendar.current
        let now = Date()
        
        do {
            let insight = try await insightsService.generateInsight(
                for: now,
                smartCategorizationEnabled: appState.smartCategorizationEnabled
            )
            currentInsight = insight
        } catch {
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            if monthToDateTotal > 0 {
                currentInsight = Insight(
                    month: monthStart,
                    text: "Spent \(formatCurrency(monthToDateTotal)) this month. Unable to generate AI insight - check console for errors."
                )
            } else {
                currentInsight = Insight(
                    month: monthStart,
                    text: "No transactions yet. Add transactions and try again."
                )
            }
        }
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
    
    private func formatCurrency(_ cents: Double) -> String {
        let dollars = cents / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

struct CategoryDetailModal: View {
    let data: [(name: String, value: Double, color: Color)]
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SPENDING BY CATEGORY")
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
                VStack(spacing: Spacing.xl) {
                    PieChartView(data: data, size: 280)
                        .padding(.top, Spacing.xl)
                    
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ForEach(data, id: \.name) { item in
                            HStack(spacing: Spacing.md) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)
                                Text(item.name)
                                    .font(.bodyEmphasized)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(formatCurrency(item.value))
                                        .font(.numeric)
                                        .foregroundColor(.textPrimary)
                                    Text("\(String(format: "%.0f", (item.value / data.reduce(0.0) { $0 + $1.value }) * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.textTertiary)
                                }
                            }
                            .padding(.vertical, Spacing.sm)
                            if item.name != data.last?.name {
                                Divider()
                                    .background(Color.divider)
                            }
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
        }
            .background(Color.backgroundPrimary)
        .frame(width: 650, height: 650)
    }
    
    private func formatCurrency(_ cents: Double) -> String {
        let dollars = cents / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}
