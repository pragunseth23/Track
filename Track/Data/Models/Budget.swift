import Foundation
import SwiftData

@Model
final class Budget: Identifiable {
    var id: UUID
    var month: Date // normalized to first of month
    var categoryId: UUID
    var limitCents: Int
    
    init(
        id: UUID = UUID(),
        month: Date,
        categoryId: UUID,
        limitCents: Int
    ) {
        self.id = id
        self.month = month
        self.categoryId = categoryId
        self.limitCents = limitCents
    }
}
