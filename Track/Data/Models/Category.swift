import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var emoji: String?
    var isSystem: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        emoji: String? = nil,
        isSystem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isSystem = isSystem
    }
}
