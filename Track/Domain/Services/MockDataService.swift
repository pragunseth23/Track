import Foundation
import SwiftData

/// Service for generating mock transaction data for testing
@MainActor
final class MockDataService {
    private let modelContext: ModelContext
    private let categoryRepository: CategoryRepositoryProtocol
    private let categorizationService: CategorizationService
    
    init(
        modelContext: ModelContext,
        categoryRepository: CategoryRepositoryProtocol,
        categorizationService: CategorizationService
    ) {
        self.modelContext = modelContext
        self.categoryRepository = categoryRepository
        self.categorizationService = categorizationService
    }
    
    /// Generate a set of mock transactions for testing
    func generateMockTransactions() async throws {
        // Get all categories
        let categories = try await categoryRepository.fetchAll()
        guard !categories.isEmpty else {
            throw MockDataError.noCategories
        }
        
        // Create a category map for quick lookup
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })
        
        // Generate transactions for the past 30 days
        let calendar = Calendar.current
        let today = Date()
        
        // More realistic/confusing merchant names that Gemma will need to clean up and categorize
        let mockTransactions: [(merchantRaw: String, amountCents: Int, daysAgo: Int, isSubscription: Bool, note: String?)] = [
            // Coffee - confusing formats
            ("SBUX*1234-5678 SEATTLE WA", -695, 0, false, nil),
            ("PEETS COFFEE #9876 BERKELEY", -525, 2, false, nil),
            ("DD #12345 BOSTON MA 02101", -425, 5, false, nil),
            ("BLUE BOTTLE COFFEE SF", -850, 8, false, nil),
            
            // Groceries - various formats
            ("WFM #1234 WHOLE FOODS MARKET", -12500, 1, false, nil),
            ("TGT*TARGET STORE T-5678", -8750, 3, false, nil),
            ("TRADER JOE'S #456 SAN FRANCISCO CA", -6250, 7, false, nil),
            ("SAFEWAY #789 123 MAIN ST", -9500, 10, false, nil),
            ("COSTCO WHOLESALE #1234", -18500, 14, false, nil),
            ("KROGER #5678 GROCERY STORE", -11200, 12, false, nil),
            
            // Food/Restaurants - ambiguous names
            ("MCD #1234 456 OAK ST", -1245, 0, false, nil),
            ("PIZZA HUT DELIVERY #9876", -2899, 1, false, nil),
            ("OLIVE GARDEN RESTAURANT #123", -4567, 4, false, "Dinner with friends"),
            ("UBER EATS ORDER #ABC123XYZ", -3245, 6, false, nil),
            ("CHIPOTLE MEXICAN GRILL #456", -1256, 8, false, nil),
            ("DOMINO'S PIZZA #789 DELIVERY", -2199, 12, false, nil),
            ("DOORDASH ORDER #XYZ789", -2899, 3, false, nil),
            
            // Transport - various formats
            ("UBER*TRIP RIDE SHARE", -1899, 0, false, nil),
            ("LYFT RIDE #ABC123", -2145, 2, false, nil),
            ("SHELL #5678 GAS STATION", -4599, 3, false, nil),
            ("CHEVRON #9012 123 HIGHWAY", -3899, 9, false, nil),
            ("BART METRO TRANSIT", -275, 11, false, nil),
            ("EXONMOBIL #3456 GAS", -4299, 15, false, nil),
            ("BP GAS STATION #7890", -3899, 7, false, nil),
            
            // Entertainment - subscription services
            ("NETFLIX.COM 9.99", -1599, 0, true, nil),
            ("SPOTIFY PREMIUM SUBSCRIPTION", -999, 0, true, nil),
            ("AMC THEATRES #1234 MOVIE", -1899, 5, false, nil),
            ("DISNEY+ MONTHLY SUB", -1099, 0, true, nil),
            ("APPLE MUSIC SUBSCRIPTION", -1099, 0, true, nil),
            ("HULU SUBSCRIPTION PLAN", -799, 0, true, nil),
            ("YOUTUBE PREMIUM SUB", -1199, 0, true, nil),
            
            // Shopping - e-commerce
            ("AMZN MKTP US*AMAZON.COM PURCHASE", -4599, 1, false, nil),
            ("NIKE.COM ONLINE STORE", -12999, 3, false, nil),
            ("APPLE STORE #1234 IPHONE", -89999, 6, false, "New iPhone"),
            ("TARGET.COM ONLINE ORDER", -3499, 8, false, nil),
            ("ADIDAS STORE #5678", -8999, 13, false, nil),
            ("EBAY*PAYPAL PURCHASE", -2499, 5, false, nil),
            
            // Bills - utilities and services
            ("COMCAST XFINITY INTERNET BILL", -7999, 0, true, nil),
            ("VERIZON WIRELESS MOBILE BILL", -8999, 0, true, nil),
            ("PG&E ELECTRIC COMPANY BILL", -12500, 5, true, nil),
            ("WATER DEPARTMENT UTILITY BILL", -4599, 5, true, nil),
            ("AT&T MOBILE PHONE BILL", -8499, 0, true, nil),
            ("T-MOBILE WIRELESS BILL", -7999, 0, true, nil),
            
            // Health - medical and pharmacy
            ("CVS PHARMACY #1234 PRESCRIPTION", -3499, 2, false, nil),
            ("WALGREENS #5678 PHARMACY", -1899, 4, false, nil),
            ("DR. SMITH MEDICAL OFFICE", -15000, 9, false, "Annual checkup"),
            ("HOSPITAL BILLING DEPARTMENT", -45000, 16, false, nil),
            ("RITE AID PHARMACY #9012", -2299, 6, false, nil),
            
            // Education
            ("UNIVERSITY TUITION PAYMENT", -500000, 20, false, "Fall semester"),
            ("COURSERA ONLINE COURSE", -9999, 11, false, nil),
            ("UDEMY COURSE PURCHASE", -1299, 8, false, nil),
            
            // Travel
            ("HOTEL RESERVATION #ABC123", -125000, 18, false, "Weekend trip"),
            ("DELTA AIRLINES TICKET", -350000, 25, false, nil),
            ("AIRBNB BOOKING #XYZ789", -89000, 22, false, nil),
            ("EXPEDIA HOTEL RESERVATION", -95000, 19, false, nil),
            ("HERTZ CAR RENTAL", -45000, 20, false, nil),
            
            // Ambiguous - need AI categorization
            ("PAYPAL*TRANSFER TO JOHN DOE", -2500, 1, false, nil),
            ("SQUARE *MERCHANT NAME HERE", -1899, 4, false, nil),
            ("VENMO PAYMENT TO JANE SMITH", -1500, 7, false, "Split dinner"),
            ("ZELLE TRANSFER TO FRIEND", -5000, 9, false, nil),
            ("CASH APP PAYMENT #123456", -2000, 14, false, nil),
            ("STRIPE*PAYMENT PROCESSING", -3500, 6, false, nil),
        ]
        
        // Create transactions and let CategorizationService categorize them
        for mock in mockTransactions {
            let date = calendar.date(byAdding: .day, value: -mock.daysAgo, to: today) ?? today
            
            do {
                // Use CategorizationService to categorize (this will use Gemma if Smart Categorization is enabled)
                let category = try await categorizationService.categorize(
                    merchant: mock.merchantRaw,
                    amount: mock.amountCents,
                    smartCategorizationEnabled: true // Always enable for mock data to test AI
                )
                
                // Normalize merchant name (CategorizationService does this, but we'll use it for merchantClean)
                let normalized = normalizeMerchantName(mock.merchantRaw)
                
                createTransaction(
                    merchantRaw: mock.merchantRaw,
                    merchantClean: normalized,
                    amountCents: mock.amountCents,
                    category: category,
                    date: date,
                    isSubscription: mock.isSubscription,
                    note: mock.note
                )
            } catch {
                print("⚠️ [MockDataService] Failed to categorize transaction: \(mock.merchantRaw) - \(error.localizedDescription)")
                // Fallback to "Other" category if categorization fails
                guard let otherCategory = categoryMap["Other"] else { continue }
                let normalized = normalizeMerchantName(mock.merchantRaw)
                createTransaction(
                    merchantRaw: mock.merchantRaw,
                    merchantClean: normalized,
                    amountCents: mock.amountCents,
                    category: otherCategory,
                    date: date,
                    isSubscription: mock.isSubscription,
                    note: mock.note
                )
            }
        }
        
        // Save all transactions
        try modelContext.save()
    }
    
    private func normalizeMerchantName(_ merchant: String) -> String {
        // Basic normalization - CategorizationService will do more sophisticated cleaning
        var normalized = merchant.trimmingCharacters(in: .whitespaces)
        
        // Remove common prefixes
        let prefixes = ["AMZN", "AMAZON", "SQ *", "SQ*", "PAYPAL", "APPLE", "GOOGLE", "UBER*", "LYFT"]
        for prefix in prefixes {
            if normalized.uppercased().hasPrefix(prefix) {
                normalized = String(normalized.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Remove numeric codes at end
        normalized = normalized.replacingOccurrences(of: #"\s+\d+$"#, with: "", options: .regularExpression)
        
        return normalized.isEmpty ? merchant : normalized
    }
    
    private func createTransaction(
        merchantRaw: String,
        merchantClean: String,
        amountCents: Int,
        category: Category,
        date: Date,
        isSubscription: Bool,
        note: String?
    ) {
        let transaction = Transaction(
            date: date,
            merchantRaw: merchantRaw,
            merchantClean: merchantClean,
            amountCents: amountCents,
            currency: "USD",
            categoryId: category.id,
            categoryNameSnapshot: category.name,
            isSubscription: isSubscription,
            note: note,
            source: "mock"
        )
        modelContext.insert(transaction)
    }
}

enum MockDataError: Error {
    case noCategories
}
