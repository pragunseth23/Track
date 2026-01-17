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
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if currentMonthBudgets.isEmpty {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.textTertiary)
                        Text("NO BUDGETS SET")
                            .font(.label)
                            .foregroundColor(.textTertiary)
                            .tracking(1.5)
                        Text("Create a budget to track spending limits")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.xxxxl)
                } else {
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
            }
            .padding(Spacing.lg)
            .padding(.bottom, 80) // Space for bottom nav
            }
            .background(Color.backgroundPrimary)
        .overlay(alignment: .bottomTrailing) {
                    Button(action: {
                        showAddBudgetSheet = true
                    }) {
                        Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 56, height: 56)
                    .background(Color.accent)
                    .clipShape(Circle())
                    .shadow(color: .accent.opacity(0.3), radius: 8)
            }
            .buttonStyle(.plain)
            .padding(Spacing.lg)
            .padding(.bottom, 80) // Above bottom nav
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
    
    private var remaining: Int {
        max(0, budget.limitCents - spent)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(category?.name.uppercased() ?? "UNKNOWN")
                        .font(.label)
                        .foregroundColor(.textTertiary)
                        .tracking(1.5)
                if budget.limitCents > 0 {
                    Text("\(formatCurrency(spent)) / \(formatCurrency(budget.limitCents))")
                            .font(.numericLarge)
                        .foregroundColor(.textPrimary)
                        Text("\(formatCurrency(remaining)) remaining")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                } else {
                    Text(formatCurrency(spent))
                            .font(.numericLarge)
                            .foregroundColor(.textPrimary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.sm) {
                    if budget.limitCents > 0 {
                        Text("\(String(format: "%.0f", percentage))%")
                        .font(.numeric)
                            .foregroundColor(progressColor)
                    }
                    if percentage >= 70 && percentage < 90 {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.captionSmall)
                                .foregroundColor(.accentWarning)
                            Text("WARNING")
                                .font(.labelSmall)
                                .foregroundColor(.accentWarning)
                        }
                    } else if percentage >= 90 {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.captionSmall)
                                .foregroundColor(.accentError)
                            Text("OVER BUDGET")
                                .font(.labelSmall)
                                .foregroundColor(.accentError)
                        }
                    }
                }
            }
            
            if budget.limitCents > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.surface)
                            .frame(height: 8)
                        
                        Rectangle()
                            .fill(progressColor)
                            .frame(
                                width: min(
                                    geometry.size.width,
                                    geometry.size.width * CGFloat(percentage / 100)
                                ),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
        }
        .dataCard()
        .contextMenu {
            Button(action: {
                showEditSheet = true
            }) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var progressColor: Color {
        if percentage >= 90 {
            return .accentError
        } else if percentage >= 70 {
            return .accentWarning
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
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName: String = ""
    @State private var budgetAmount: String = ""
    @State private var errorMessage: String?
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ADD BUDGET")
                    .font(.headerSmall)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            .divider()
            
            Form {
                Section {
                    TextField("Category Name", text: $categoryName)
                        .foregroundColor(.textPrimary)
                        .font(.body)
                }
                
                Section {
                    HStack {
                        Text("$")
                            .foregroundColor(.textSecondary)
                            .font(.numeric)
                        TextField("0", text: $budgetAmount)
                            .foregroundColor(.textPrimary)
                            .font(.numeric)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.accentError)
                            .font(.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            
            // Footer
            HStack(spacing: Spacing.md) {
                    Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.textSecondary)
                
                Spacer()
                
                    Button("Save") {
                        saveBudget()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
            }
            .padding(Spacing.lg)
            .divider()
        }
        .background(Color.backgroundPrimary)
        .frame(width: 520, height: 320)
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
        dismiss()
    }
}
