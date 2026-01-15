import Foundation
import SwiftData

protocol TransactionRepositoryProtocol {
    func fetchAll() async throws -> [Transaction]
    func fetchByDateRange(start: Date, end: Date) async throws -> [Transaction]
    func fetchByCategory(_ categoryId: UUID) async throws -> [Transaction]
    func fetchSubscriptions() async throws -> [Transaction]
    func save(_ transaction: Transaction) async throws
    func delete(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
}

@MainActor
final class TransactionRepository: TransactionRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchByDateRange(start: Date, end: Date) async throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.date >= start && transaction.date <= end
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchByCategory(_ categoryId: UUID) async throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.categoryId == categoryId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchSubscriptions() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.isSubscription == true
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func save(_ transaction: Transaction) async throws {
        modelContext.insert(transaction)
        try modelContext.save()
    }
    
    func delete(_ transaction: Transaction) async throws {
        modelContext.delete(transaction)
        try modelContext.save()
    }
    
    func update(_ transaction: Transaction) async throws {
        try modelContext.save()
    }
}
