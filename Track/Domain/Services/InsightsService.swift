import Foundation
import SwiftUI

@MainActor
final class InsightsService {
    private let transactionRepository: TransactionRepositoryProtocol
    private let budgetRepository: BudgetRepositoryProtocol
    private let insightRepository: InsightRepositoryProtocol
    
    init(
        transactionRepository: TransactionRepositoryProtocol,
        budgetRepository: BudgetRepositoryProtocol,
        insightRepository: InsightRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.insightRepository = insightRepository
    }
    
    func generateInsight(for month: Date, smartCategorizationEnabled: Bool) async throws -> Insight {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
        
        // Fetch current month transactions
        let currentTransactions = try await transactionRepository.fetchByDateRange(
            start: startOfMonth,
            end: endOfMonth
        )
        
        // Fetch previous month transactions
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? startOfMonth
        let previousMonthStart = calendar.dateInterval(of: .month, for: previousMonth)?.start ?? previousMonth
        let previousMonthEnd = calendar.dateInterval(of: .month, for: previousMonth)?.end ?? previousMonth
        let previousTransactions = try await transactionRepository.fetchByDateRange(
            start: previousMonthStart,
            end: previousMonthEnd
        )
        
        // Calculate metrics
        let currentTotal = currentTransactions
            .filter { $0.amountCents < 0 }
            .reduce(0) { $0 + abs($1.amountCents) }
        
        let previousTotal = previousTransactions
            .filter { $0.amountCents < 0 }
            .reduce(0) { $0 + abs($1.amountCents) }
        
        // Calculate top categories
        let categorySpending = Dictionary(grouping: currentTransactions.filter { $0.amountCents < 0 }) { $0.categoryNameSnapshot }
            .mapValues { transactions in
                transactions.reduce(0) { $0 + abs($1.amountCents) }
            }
        let topCategories = categorySpending.sorted { $0.value > $1.value }.prefix(3)
        
        // Calculate subscription total
        let subscriptionTotal = currentTransactions
            .filter { $0.isSubscription && $0.amountCents < 0 }
            .reduce(0) { $0 + abs($1.amountCents) }
        
        // Calculate month-over-month change
        let momChange: Double
        if previousTotal > 0 {
            momChange = ((Double(currentTotal) - Double(previousTotal)) / Double(previousTotal)) * 100
        } else {
            momChange = currentTotal > 0 ? 100 : 0
        }
        
        // Generate insight text (deterministic)
        var insightText = "Spent \(formatCurrency(currentTotal)) this month"
        
        if previousTotal > 0 {
            let changeSign = momChange >= 0 ? "+" : ""
            insightText += ", \(changeSign)\(String(format: "%.0f", momChange))% vs last month"
        }
        
        if let topCategory = topCategories.first {
            insightText += ". Top category: \(topCategory.key) (\(formatCurrency(topCategory.value)))"
        }
        
        if subscriptionTotal > 0 {
            insightText += ". \(formatCurrency(subscriptionTotal)) in subscriptions"
        }
        
        // Check if existing insight exists
        if let existing = try await insightRepository.fetchForMonth(month) {
            existing.text = insightText
            try await insightRepository.save(existing)
            return existing
        }
        
        let insight = Insight(month: startOfMonth, text: insightText)
        try await insightRepository.save(insight)
        return insight
    }
    
    func calculateBudgetStatus(for month: Date) async throws -> BudgetStatus {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
        
        let budgets = try await budgetRepository.fetchForMonth(month)
        let transactions = try await transactionRepository.fetchByDateRange(start: startOfMonth, end: endOfMonth)
        
        if budgets.isEmpty {
            // No budgets - use MoM change
            let currentTotal = transactions
                .filter { $0.amountCents < 0 }
                .reduce(0) { $0 + abs($1.amountCents) }
            
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? startOfMonth
            let previousMonthStart = calendar.dateInterval(of: .month, for: previousMonth)?.start ?? previousMonth
            let previousMonthEnd = calendar.dateInterval(of: .month, for: previousMonth)?.end ?? previousMonth
            let previousTransactions = try await transactionRepository.fetchByDateRange(
                start: previousMonthStart,
                end: previousMonthEnd
            )
            
            let previousTotal = previousTransactions
                .filter { $0.amountCents < 0 }
                .reduce(0) { $0 + abs($1.amountCents) }
            
            let momChange: Double
            if previousTotal > 0 {
                momChange = ((Double(currentTotal) - Double(previousTotal)) / Double(previousTotal)) * 100
            } else {
                momChange = currentTotal > 0 ? 20 : 0
            }
            
            if abs(momChange) <= 20 {
                return .onTrack
            } else {
                return .trendingHigh
            }
        } else {
            // Calculate total budget vs spending
            let totalBudget = budgets.reduce(0) { $0 + $1.limitCents }
            let categorySpending = Dictionary(grouping: transactions.filter { $0.amountCents < 0 }) { $0.categoryId }
                .mapValues { transactions in
                    transactions.reduce(0) { $0 + abs($1.amountCents) }
                }
            
            var totalSpent = 0
            for budget in budgets {
                totalSpent += categorySpending[budget.categoryId] ?? 0
            }
            
            let percentage = Double(totalSpent) / Double(totalBudget) * 100
            
            if percentage < 80 {
                return .onTrack
            } else if percentage < 100 {
                return .trendingHigh
            } else {
                return .overBudget
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
}

enum BudgetStatus {
    case onTrack
    case trendingHigh
    case overBudget
    
    var text: String {
        switch self {
        case .onTrack: return "ON TRACK"
        case .trendingHigh: return "TRENDING HIGH"
        case .overBudget: return "OVER BUDGET"
        }
    }
    
    var color: Color {
        switch self {
        case .onTrack: return .statusOnTrack
        case .trendingHigh: return .statusTrendingHigh
        case .overBudget: return .statusOverBudget
        }
    }
}
