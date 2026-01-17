import Foundation
import SwiftUI

@MainActor
final class InsightsService {
    private let transactionRepository: TransactionRepositoryProtocol
    private let budgetRepository: BudgetRepositoryProtocol
    private let insightRepository: InsightRepositoryProtocol
    private let llmClient: LLMClient?
    
    init(
        transactionRepository: TransactionRepositoryProtocol,
        budgetRepository: BudgetRepositoryProtocol,
        insightRepository: InsightRepositoryProtocol,
        llmClient: LLMClient? = nil
    ) {
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.insightRepository = insightRepository
        self.llmClient = llmClient
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
        
        // If no transactions, return a default insight
        if currentTransactions.isEmpty {
            let insight = Insight(
                month: startOfMonth,
                text: "No transactions yet this month. Start adding transactions to get personalized insights about your spending."
            )
            try await insightRepository.save(insight)
            return insight
        }
        
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
        let topCategories = Array(categorySpending.sorted { $0.value > $1.value }.prefix(3))
        
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
        
        // Generate insight text
        let insightText: String
        
        // Calculate additional metrics for richer insights
        let transactionCount = currentTransactions.filter { $0.amountCents < 0 }.count
        let averageTransactionSize = transactionCount > 0 ? currentTotal / transactionCount : 0
        let subscriptionCount = currentTransactions.filter { $0.isSubscription && $0.amountCents < 0 }.count
        let largestTransaction = currentTransactions.filter { $0.amountCents < 0 }.max(by: { abs($0.amountCents) < abs($1.amountCents) })
        
        // Calculate category changes
        let previousCategorySpending = Dictionary(grouping: previousTransactions.filter { $0.amountCents < 0 }) { $0.categoryNameSnapshot }
            .mapValues { transactions in
                transactions.reduce(0) { $0 + abs($1.amountCents) }
            }
        
        var categoryChanges: [String: Double] = [:]
        for (category, currentAmount) in categorySpending {
            let previousAmount = previousCategorySpending[category] ?? 0
            if previousAmount > 0 {
                let change = ((Double(currentAmount) - Double(previousAmount)) / Double(previousAmount)) * 100
                categoryChanges[category] = change
            }
        }
        
        // If LLM client is available and smart categorization is enabled, use AI
        if let llmClient = llmClient, smartCategorizationEnabled {
            // Build comprehensive transaction summary for LLM
            var summary = "SPENDING OVERVIEW:\n"
            summary += "- Total spending this month: \(formatCurrency(currentTotal))\n"
            summary += "- Number of transactions: \(transactionCount)\n"
            summary += "- Average transaction size: \(formatCurrency(averageTransactionSize))\n"
        
        if previousTotal > 0 {
            let changeSign = momChange >= 0 ? "+" : ""
                summary += "- Month-over-month change: \(changeSign)\(String(format: "%.1f", momChange))%\n"
                summary += "- Previous month total: \(formatCurrency(previousTotal))\n"
            } else {
                summary += "- This is the first month with transactions\n"
        }
        
            if !topCategories.isEmpty {
                summary += "\nTOP SPENDING CATEGORIES:\n"
                for (index, category) in topCategories.enumerated() {
                    let percentage = (Double(category.value) / Double(currentTotal)) * 100
                    summary += "\(index + 1). \(category.key): \(formatCurrency(category.value)) (\(String(format: "%.1f", percentage))%)\n"
                    
                    if let change = categoryChanges[category.key] {
                        let changeSign = change >= 0 ? "+" : ""
                        summary += "   Change from last month: \(changeSign)\(String(format: "%.1f", change))%\n"
                    }
                }
        }
        
        if subscriptionTotal > 0 {
                let subscriptionPercentage = (Double(subscriptionTotal) / Double(currentTotal)) * 100
                summary += "\nSUBSCRIPTIONS:\n"
                summary += "- Total subscription spending: \(formatCurrency(subscriptionTotal)) (\(String(format: "%.1f", subscriptionPercentage))% of total)\n"
                summary += "- Number of subscriptions: \(subscriptionCount)\n"
                summary += "- Average subscription cost: \(formatCurrency(subscriptionTotal / max(subscriptionCount, 1)))\n"
            }
            
            if let largest = largestTransaction {
                summary += "\nNOTABLE TRANSACTIONS:\n"
                summary += "- Largest transaction: \(largest.merchantClean) - \(formatCurrency(abs(largest.amountCents)))\n"
            }
            
            // Get AI-generated insight
            do {
                insightText = try await llmClient.generateInsight(transactionSummary: summary)
            } catch {
                // Fallback to deterministic insight if LLM fails
                print("LLM insight generation failed: \(error.localizedDescription), using fallback")
                insightText = generateDeterministicInsight(
                    currentTotal: currentTotal,
                    previousTotal: previousTotal,
                    momChange: momChange,
                    topCategories: topCategories,
                    subscriptionTotal: subscriptionTotal
                )
            }
        } else {
            // Use deterministic insight
            insightText = generateDeterministicInsight(
                currentTotal: currentTotal,
                previousTotal: previousTotal,
                momChange: momChange,
                topCategories: topCategories,
                subscriptionTotal: subscriptionTotal
            )
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
    
    private func generateDeterministicInsight(
        currentTotal: Int,
        previousTotal: Int,
        momChange: Double,
        topCategories: [(key: String, value: Int)],
        subscriptionTotal: Int
    ) -> String {
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
        
        return insightText
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
