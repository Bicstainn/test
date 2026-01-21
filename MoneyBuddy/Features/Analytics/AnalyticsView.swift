//
//  AnalyticsView.swift
//  MoneyBuddy
//
//  Statistics and analytics dashboard
//

import SwiftUI
import SwiftData
import Charts

/// Analytics view with charts and statistics
struct AnalyticsView: View {
    /// Transaction store
    @ObservedObject var store: TransactionStore

    /// Selected time range
    @State private var selectedRange: TimeRange = .month

    /// Show AI weekly report
    @State private var showWeeklyReport: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    Picker("时间范围", selection: $selectedRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Summary cards
                    summaryCards

                    // Daily expense chart
                    dailyExpenseChart

                    // Category breakdown
                    categoryBreakdown

                    // AI weekly report button
                    weeklyReportButton
                }
                .padding(.vertical)
            }
            .navigationTitle("统计")
            .sheet(isPresented: $showWeeklyReport) {
                WeeklyReportView(store: store)
            }
        }
    }

    /// Current transactions based on selected range
    private var currentTransactions: [Transaction] {
        switch selectedRange {
        case .week:
            return store.currentWeekTransactions
        case .month:
            return store.currentMonthTransactions
        case .year:
            let calendar = Calendar.current
            let now = Date()
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear)!
            return store.transactions(from: startOfYear, to: endOfYear)
        }
    }

    /// Summary cards
    private var summaryCards: some View {
        let stats = store.statistics(for: currentTransactions)

        return HStack(spacing: 12) {
            SummaryCard(
                title: "支出",
                value: stats.totalExpense,
                icon: "arrow.up.circle.fill",
                color: .red
            )

            SummaryCard(
                title: "收入",
                value: stats.totalIncome,
                icon: "arrow.down.circle.fill",
                color: .green
            )

            SummaryCard(
                title: "结余",
                value: stats.balance,
                icon: "equal.circle.fill",
                color: stats.balance >= 0 ? .blue : .orange
            )
        }
        .padding(.horizontal)
    }

    /// Daily expense bar chart
    private var dailyExpenseChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日支出")
                .font(.headline)
                .padding(.horizontal)

            let dailyData = store.dailyExpenses(days: 7)

            Chart(dailyData, id: \.date) { item in
                BarMark(
                    x: .value("日期", item.date, unit: .day),
                    y: .value("金额", item.amount)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let amount = value.as(Decimal.self) {
                            Text("¥\(amount as NSDecimalNumber, formatter: shortCurrencyFormatter)")
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    /// Category breakdown pie chart
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类占比")
                .font(.headline)
                .padding(.horizontal)

            let breakdown = store.categoryExpenses(currentTransactions)

            if breakdown.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(breakdown, id: \.category) { item in
                    SectorMark(
                        angle: .value("金额", item.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(hex: item.category.colorHex))
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .padding(.horizontal)

                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(breakdown.prefix(6), id: \.category) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: item.category.colorHex))
                                .frame(width: 12, height: 12)
                            Text(item.category.rawValue)
                                .font(.caption)
                            Spacer()
                            Text("¥\(item.amount as NSDecimalNumber, formatter: shortCurrencyFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    /// Weekly report button
    private var weeklyReportButton: some View {
        Button {
            showWeeklyReport = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("AI周报分析")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    /// Short currency formatter
    private var shortCurrencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

/// Time range selection
enum TimeRange: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case year = "本年"
}

/// Summary card view
struct SummaryCard: View {
    let title: String
    let value: Decimal
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("¥\(value as NSDecimalNumber, formatter: currencyFormatter)")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

#Preview {
    AnalyticsView(store: TransactionStore(modelContext: try! ModelContainer(for: Transaction.self).mainContext))
}
