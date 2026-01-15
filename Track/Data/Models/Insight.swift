import Foundation
import SwiftData

@Model
final class Insight {
    var id: UUID
    var month: Date
    var text: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        month: Date,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.month = month
        self.text = text
        self.createdAt = createdAt
    }
}
