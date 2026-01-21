//
//  DashboardView.swift
//  MoneyBuddy
//
//  Transaction list and overview dashboard
//

import SwiftUI
import SwiftData

/// Main dashboard view showing transaction list
struct DashboardView: View {
    /// Transaction store
    @ObservedObject var store: TransactionStore

    /// Search text
    @State private var searchText: String = ""

    /// Selected transaction for detail view
    @State private var selectedTransaction: Transaction?

    /// Show delete confirmation
    @State private var transactionToDelete: Transaction?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary header
                summaryHeader

                // Transaction list
                if filteredTransactions.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
            .navigationTitle("账单")
            .searchable(text: $searchText, prompt: "搜索商家或备注")
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(
                    transaction: transaction,
                    store: store,
                    onDelete: {
                        selectedTransaction = nil
                    }
                )
            }
            .alert("确认删除", isPresented: .constant(transactionToDelete != nil)) {
                Button("删除", role: .destructive) {
                    if let transaction = transactionToDelete {
                        store.delete(transaction)
                    }
                    transactionToDelete = nil
                }
                Button("取消", role: .cancel) {
                    transactionToDelete = nil
                }
            } message: {
                Text("确定要删除这条记录吗？")
            }
        }
    }

    /// Summary header with totals
    private var summaryHeader: some View {
        let stats = store.statistics(for: store.currentMonthTransactions)

        return VStack(spacing: 12) {
            Text("本月支出")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("¥\(stats.totalExpense as NSDecimalNumber, formatter: currencyFormatter)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)

            HStack(spacing: 24) {
                VStack {
                    Text("收入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(stats.totalIncome as NSDecimalNumber, formatter: currencyFormatter)")
                        .font(.headline)
                        .foregroundColor(.green)
                }

                Divider()
                    .frame(height: 30)

                VStack {
                    Text("笔数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.transactionCount)")
                        .font(.headline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    /// Empty state view
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("暂无账单记录")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("通过快捷指令或手动记账开始记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Transaction list grouped by date
    private var transactionList: some View {
        List {
            ForEach(groupedTransactions, id: \.date) { group in
                Section {
                    ForEach(group.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTransaction = transaction
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    transactionToDelete = transaction
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(group.dateString)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// Filter transactions by search text
    private var filteredTransactions: [Transaction] {
        guard !searchText.isEmpty else {
            return store.transactions
        }

        let lowercased = searchText.lowercased()
        return store.transactions.filter { tx in
            tx.merchant?.lowercased().contains(lowercased) == true ||
            tx.note?.lowercased().contains(lowercased) == true ||
            tx.category.rawValue.contains(lowercased)
        }
    }

    /// Group transactions by date
    private var groupedTransactions: [DateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { tx in
            calendar.startOfDay(for: tx.date)
        }

        return grouped.map { date, transactions in
            DateGroup(date: date, transactions: transactions.sorted { $0.date > $1.date })
        }.sorted { $0.date > $1.date }
    }

    /// Currency formatter
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

/// Date group for section display
struct DateGroup {
    let date: Date
    let transactions: [Transaction]

    var dateString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            formatter.dateFormat = "MM月dd日 EEEE"
            return formatter.string(from: date)
        }
    }
}

/// Transaction row view
struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: transaction.category.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color(hex: transaction.category.colorHex))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayTitle)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(transaction.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if transaction.aiClassified {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }

                    Text(transaction.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Amount
            Text(transaction.formattedAmount)
                .font(.headline)
                .foregroundColor(transaction.type == .expense ? .primary : .green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DashboardView(store: TransactionStore(modelContext: try! ModelContainer(for: Transaction.self).mainContext))
}
