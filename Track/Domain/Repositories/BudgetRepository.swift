import Foundation
import SwiftData

protocol BudgetRepositoryProtocol {
    func fetchForMonth(_ month: Date) async throws -> [Budget]
    func fetchForCategory(_ categoryId: UUID) async throws -> [Budget]
    func save(_ budget: Budget) async throws
    func delete(_ budget: Budget) async throws
}

@MainActor
final class BudgetRepository: BudgetRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchForMonth(_ month: Date) async throws -> [Budget] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { budget in
                budget.month == startOfMonth
            },
            sortBy: [SortDescriptor(\.limitCents, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchForCategory(_ categoryId: UUID) async throws -> [Budget] {
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { budget in
                budget.categoryId == categoryId
            },
            sortBy: [SortDescriptor(\.month, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func save(_ budget: Budget) async throws {
        modelContext.insert(budget)
        try modelContext.save()
    }
    
    func delete(_ budget: Budget) async throws {
        modelContext.delete(budget)
        try modelContext.save()
    }
}
