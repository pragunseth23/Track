import Foundation
import SwiftData

protocol InsightRepositoryProtocol {
    func fetchForMonth(_ month: Date) async throws -> Insight?
    func save(_ insight: Insight) async throws
    func delete(_ insight: Insight) async throws
}

@MainActor
final class InsightRepository: InsightRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchForMonth(_ month: Date) async throws -> Insight? {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        
        let descriptor = FetchDescriptor<Insight>(
            predicate: #Predicate<Insight> { insight in
                insight.month == startOfMonth
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func save(_ insight: Insight) async throws {
        modelContext.insert(insight)
        try modelContext.save()
    }
    
    func delete(_ insight: Insight) async throws {
        modelContext.delete(insight)
        try modelContext.save()
    }
}
