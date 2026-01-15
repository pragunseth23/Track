import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var date: Date
    var merchantRaw: String
    var merchantClean: String
    var amountCents: Int // negative = expense
    var currency: String
    var categoryId: UUID
    var categoryNameSnapshot: String
    var isSubscription: Bool
    var note: String?
    var source: String
    
    init(
        id: UUID = UUID(),
        date: Date,
        merchantRaw: String,
        merchantClean: String,
        amountCents: Int,
        currency: String = "USD",
        categoryId: UUID,
        categoryNameSnapshot: String,
        isSubscription: Bool = false,
        note: String? = nil,
        source: String = "manual"
    ) {
        self.id = id
        self.date = date
        self.merchantRaw = merchantRaw
        self.merchantClean = merchantClean
        self.amountCents = amountCents
        self.currency = currency
        self.categoryId = categoryId
        self.categoryNameSnapshot = categoryNameSnapshot
        self.isSubscription = isSubscription
        self.note = note
        self.source = source
    }
}
