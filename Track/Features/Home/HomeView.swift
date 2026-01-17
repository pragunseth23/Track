import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var insights: [Insight]
    
    @StateObject private var appState: AppState
    @State private var monthToDateTotal: Int = 0
    @State private var momChange: Double = 0
    @State private var categorySpending: [(name: String, value: Double, color: Color)] = []
    @State private var currentInsight: Insight?
    @State private var showCategoryDetail = false
    @State private var isGeneratingInsight = false
    
    private var insightsService: InsightsService {
        let transactionRepository = TransactionRepository(modelContext: modelContext)
        let insightRepository = InsightRepository(modelContext: modelContext)
        let llmClient = appState.createLLMClient()
        return InsightsService(
            transactionRepository: transactionRepository,
            insightRepository: insightRepository,
            llmClient: llmClient
        )
    }
    
    init(appState: AppState) {
        _appState = StateObject(wrappedValue: appState)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height - 80 - (Spacing.lg * 3) - 140
                VStack(spacing: Spacing.lg) {
                // Technical metrics header - balanced spacing
                HStack(alignment: .top, spacing: Spacing.xxl) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("MONTH TO DATE")
                            .sectionHeader()
                        Text(formatCurrency(monthToDateTotal))
                            .font(.numericXLarge)
                            .foregroundColor(.textPrimary)
                        if momChange != 0 {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: momChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.captionSmall)
                                    .foregroundColor(momChange >= 0 ? .accentSecondary : .accentError)
                                Text("\(String(format: "%.1f", abs(momChange)))% vs last month")
                                .font(.caption)
                                    .foregroundColor(momChange >= 0 ? .textSecondary : .accentError)
                            }
                            .padding(.top, Spacing.xs)
                        }
                    }
                    Spacer()
                }
                    .padding(Spacing.lg)
                .dataCard()
                    
                // Grid layout for data cards - Fill to bottom
                HStack(alignment: .top, spacing: Spacing.lg) {
                    // Spending by Category
                    Button(action: {
                        showCategoryDetail = true
                    }) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Text("SPENDING BY CATEGORY")
                                    .sectionHeader()
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
                            
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .buttonStyle(.plain)
                    .dataCard()
                    
                    // Insights card - Equal height
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("AI INSIGHT")
                                .sectionHeader()
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
                                        .scaleEffect(0.8)
                                        .tint(.accent)
                                        .frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                        .frame(width: 36, height: 36)
                                        .background(Color.accent)
                                        .clipShape(Circle())
                                        .shadow(color: .accent.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(isGeneratingInsight)
                        }
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                    if let insight = currentInsight {
                                    // Parse and display as bullet points
                                    let bulletPoints = parseBulletPoints(insight.text)
                                    ForEach(Array(bulletPoints.enumerated()), id: \.offset) { index, point in
                                        HStack(alignment: .top, spacing: Spacing.sm) {
                                            Text("•")
                                                .font(.body)
                                                .foregroundColor(.accent)
                                            Text(point)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                                .lineSpacing(4)
                                        }
                                    }
                                } else {
                                    Text("Tap refresh to generate insights based on your transactions.")
                                        .font(.bodySmall)
                                        .foregroundColor(.textTertiary)
                                        .lineSpacing(6)
                                }
                            }
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .dataCard()
                }
                .frame(height: max(availableHeight, CardDimensions.standardHeight))
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
        
        print("🔄 [HomeView] Starting insight generation...")
        do {
            let insight = try await insightsService.generateInsight(for: now)
            currentInsight = insight
            print("✅ [HomeView] Insight generated and displayed in UI")
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
    
    private func parseBulletPoints(_ text: String) -> [String] {
        // Parse bullet points from text (handles •, -, or numbered lists)
        let lines = text.components(separatedBy: .newlines)
        var points: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // Check for bullet point markers
            if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                let point = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                if !point.isEmpty {
                    points.append(point)
                }
            } else if trimmed.range(of: #"^\d+[\.\)]\s"#, options: .regularExpression) != nil {
                // Numbered list item
                let point = trimmed.replacingOccurrences(of: #"^\d+[\.\)]\s"#, with: "", options: .regularExpression)
                if !point.isEmpty {
                    points.append(point)
                }
            } else if !points.isEmpty {
                // Continue previous point if no bullet marker
                points[points.count - 1] += " " + trimmed
            } else {
                // First line without bullet - treat as single point
                points.append(trimmed)
            }
        }
        
        // If no bullet points found, split by sentences
        if points.isEmpty {
            let sentences = text.components(separatedBy: ". ")
            points = sentences.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ".", with: "") }
        }
        
        return points
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
