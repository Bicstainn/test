//
//  TransactionStore.swift
//  MoneyBuddy
//
//  SwiftData transaction storage and management
//

import Foundation
import SwiftData

/// Transaction storage and query service
@MainActor
final class TransactionStore: ObservableObject {
    /// Model context for SwiftData operations
    private let modelContext: ModelContext

    /// Published list of transactions for UI binding
    @Published private(set) var transactions: [Transaction] = []

    /// Initialize with model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTransactions()
    }

    // MARK: - CRUD Operations

    /// Add new transaction
    /// - Parameter transaction: Transaction to add
    func add(_ transaction: Transaction) {
        modelContext.insert(transaction)
        save()
        fetchTransactions()
    }

    /// Create and add transaction from parsed data
    /// - Parameters:
    ///   - parsed: Parsed transaction data
    ///   - category: Category (may be overridden by user)
    ///   - source: Data source
    /// - Returns: Created transaction
    @discardableResult
    func createFromParsed(
        _ parsed: ParsedTransaction,
        category: Category,
        source: DataSource
    ) -> Transaction {
        let transaction = Transaction(
            amount: parsed.amount ?? 0,
            type: parsed.type,
            category: category,
            merchant: parsed.merchant,
            date: Date(),
            source: source,
            bankName: parsed.bankName,
            cardSuffix: parsed.cardSuffix,
            paymentSource: parsed.paymentSource,
            aiClassified: false
        )
        add(transaction)
        return transaction
    }

    /// Update existing transaction
    /// - Parameter transaction: Transaction to update
    func update(_ transaction: Transaction) {
        save()
        fetchTransactions()
    }

    /// Delete transaction
    /// - Parameter transaction: Transaction to delete
    func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
        save()
        fetchTransactions()
    }

    /// Delete multiple transactions
    /// - Parameter transactions: Transactions to delete
    func delete(_ transactions: [Transaction]) {
        for transaction in transactions {
            modelContext.delete(transaction)
        }
        save()
        fetchTransactions()
    }

    // MARK: - Queries

    /// Fetch all transactions sorted by date
    func fetchTransactions() {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            transactions = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch transactions: \(error)")
            transactions = []
        }
    }

    /// Get transactions for a specific date range
    func transactions(from startDate: Date, to endDate: Date) -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { tx in
                tx.date >= startDate && tx.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    /// Get transactions for current month
    var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        return transactions(from: startOfMonth, to: endOfMonth)
    }

    /// Get transactions for current week
    var currentWeekTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!

        return transactions(from: startOfWeek, to: endOfWeek)
    }

    /// Get transactions for today
    var todayTransactions: [Transaction] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return transactions(from: startOfDay, to: endOfDay)
    }

    // MARK: - Statistics

    /// Total expense for a list of transactions
    func totalExpense(_ transactions: [Transaction]) -> Decimal {
        transactions
            .filter { $0.type == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// Total income for a list of transactions
    func totalIncome(_ transactions: [Transaction]) -> Decimal {
        transactions
            .filter { $0.type == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// Group transactions by category
    func groupByCategory(_ transactions: [Transaction]) -> [Category: [Transaction]] {
        Dictionary(grouping: transactions) { $0.category }
    }

    /// Category expense summary
    func categoryExpenses(_ transactions: [Transaction]) -> [(category: Category, amount: Decimal)] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses) { $0.category }

        return grouped.map { category, txs in
            (category, txs.reduce(Decimal(0)) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }

    /// Daily expense totals for chart
    func dailyExpenses(days: Int = 7) -> [(date: Date, amount: Decimal)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<days).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            let dayTransactions = transactions(from: date, to: nextDay)
            let total = totalExpense(dayTransactions)
            return (date, total)
        }
    }

    // MARK: - Private

    /// Save context changes
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

// MARK: - Statistics Struct

/// Statistics summary
struct TransactionStatistics {
    let totalExpense: Decimal
    let totalIncome: Decimal
    let transactionCount: Int
    let categoryBreakdown: [(category: Category, amount: Decimal, percentage: Double)]

    var balance: Decimal {
        totalIncome - totalExpense
    }
}

extension TransactionStore {
    /// Generate statistics for transactions
    func statistics(for transactions: [Transaction]) -> TransactionStatistics {
        let expense = totalExpense(transactions)
        let income = totalIncome(transactions)
        let categoryAmounts = categoryExpenses(transactions)

        let total = expense > 0 ? expense : 1
        let breakdown = categoryAmounts.map { cat, amount in
            (cat, amount, Double(truncating: (amount / total * 100) as NSDecimalNumber))
        }

        return TransactionStatistics(
            totalExpense: expense,
            totalIncome: income,
            transactionCount: transactions.count,
            categoryBreakdown: breakdown
        )
    }
}
