import Foundation
import SwiftData

protocol CategoryRepositoryProtocol {
    func fetchAll() async throws -> [Category]
    func fetchSystemCategories() async throws -> [Category]
    func fetchById(_ id: UUID) async throws -> Category?
    func save(_ category: Category) async throws
}

@MainActor
final class CategoryRepository: CategoryRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchSystemCategories() async throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { category in
                category.isSystem == true
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchById(_ id: UUID) async throws -> Category? {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { category in
                category.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func save(_ category: Category) async throws {
        modelContext.insert(category)
        try modelContext.save()
    }
}
