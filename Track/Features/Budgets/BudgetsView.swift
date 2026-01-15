import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var categories: [Category]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    @State private var showAddBudgetSheet = false
    
    private var currentMonthBudgets: [Budget] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return budgets.filter { budget in
            calendar.isDate(budget.month, equalTo: startOfMonth, toGranularity: .month)
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if currentMonthBudgets.isEmpty {
                    VStack {
                        Spacer()
                        Text("No budgets set")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(currentMonthBudgets) { budget in
                            BudgetCard(
                                budget: budget,
                                category: categories.first(where: { $0.id == budget.categoryId }),
                                transactions: transactions,
                                onEdit: {
                                    // Edit action
                                },
                                onDelete: {
                                    modelContext.delete(budget)
                                    try? modelContext.save()
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddBudgetSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddBudgetSheet) {
                AddBudgetSheet(
                    categories: categories,
                    existingBudgets: currentMonthBudgets,
                    isPresented: $showAddBudgetSheet
                )
            }
        }
    }
}

struct BudgetCard: View {
    let budget: Budget
    let category: Category?
    let transactions: [Transaction]
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showEditSheet = false
    
    private var spent: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: budget.month)?.start ?? budget.month
        let endOfMonth = calendar.dateInterval(of: .month, for: budget.month)?.end ?? budget.month
        
        return transactions
            .filter { transaction in
                transaction.categoryId == budget.categoryId &&
                transaction.date >= startOfMonth &&
                transaction.date <= endOfMonth &&
                transaction.amountCents < 0
            }
            .reduce(0) { $0 + abs($1.amountCents) }
    }
    
    private var percentage: Double {
        guard budget.limitCents > 0 else { return 0 }
        return Double(spent) / Double(budget.limitCents) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(category?.name ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                if budget.limitCents > 0 {
                    Text("\(formatCurrency(spent)) / \(formatCurrency(budget.limitCents))")
                        .font(.numeric)
                        .foregroundColor(.textPrimary)
                } else {
                    Text(formatCurrency(spent))
                        .font(.numeric)
                        .foregroundColor(.textPrimary)
                }
            }
            
            if budget.limitCents > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.textSecondary.opacity(0.2))
                            .frame(height: 9) // 6 * 1.5 = 9
                        
                        Rectangle()
                            .fill(progressColor)
                            .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(percentage / 100)), height: 9) // 6 * 1.5 = 9
                    }
                }
                .frame(height: 9) // 6 * 1.5 = 9
                
                HStack(spacing: Spacing.sm) {
                    if percentage >= 70 && percentage < 90 {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.statusTrendingHigh)
                    } else if percentage >= 90 {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.destructive)
                    }
                    Spacer()
                }
            }
        }
        .padding(Spacing.lg)
        .darkCard()
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: {
                showEditSheet = true
            }) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.accent)
        }
    }
    
    private var progressColor: Color {
        if percentage >= 90 {
            return .destructive
        } else if percentage >= 70 {
            return .statusTrendingHigh
        } else {
            return .accent
        }
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

struct AddBudgetSheet: View {
    let categories: [Category]
    let existingBudgets: [Budget]
    @Binding var isPresented: Bool
    
    @State private var categoryName: String = ""
    @State private var budgetAmount: String = ""
    @State private var errorMessage: String?
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    TextField("Category Name", text: $categoryName)
                        .foregroundColor(.textPrimary)
                }
                
                Section("Budget Amount") {
                    HStack {
                        Text("$")
                            .foregroundColor(.textSecondary)
                        TextField("0", text: $budgetAmount)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.destructive)
                            .font(.caption)
                    }
                }
            }
            .background(Color.backgroundPrimary)
            .scrollContentBackground(.hidden)
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .foregroundColor(.accent)
                }
            }
        }
    }
    
    private func saveBudget() {
        guard !categoryName.isEmpty else {
            errorMessage = "Category name is required"
            return
        }
        
        guard let amount = Double(budgetAmount), amount > 0 else {
            errorMessage = "Budget amount must be greater than 0"
            return
        }
        
        // Check if budget already exists for this category
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        if let existingCategory = categories.first(where: { $0.name.lowercased() == categoryName.lowercased() }) {
            if existingBudgets.contains(where: { $0.categoryId == existingCategory.id }) {
                errorMessage = "Budget already exists for this category"
                return
            }
            
            let budget = Budget(
                month: startOfMonth,
                categoryId: existingCategory.id,
                limitCents: Int(amount * 100)
            )
            modelContext.insert(budget)
        } else {
            // Create new category
            let newCategory = Category(name: categoryName, isSystem: false)
            modelContext.insert(newCategory)
            
            let budget = Budget(
                month: startOfMonth,
                categoryId: newCategory.id,
                limitCents: Int(amount * 100)
            )
            modelContext.insert(budget)
        }
        
        try? modelContext.save()
        isPresented = false
    }
}
