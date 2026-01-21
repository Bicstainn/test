//
//  MoneyBuddyWidget.swift
//  MoneyBuddyWidget
//
//  iOS Widget for quick expense overview
//

import WidgetKit
import SwiftUI

/// Widget entry with transaction data
struct MoneyBuddyEntry: TimelineEntry {
    let date: Date
    let todayExpense: Decimal
    let monthExpense: Decimal
    let transactionCount: Int
    let topCategory: String?
}

/// Widget timeline provider
struct MoneyBuddyProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoneyBuddyEntry {
        MoneyBuddyEntry(
            date: Date(),
            todayExpense: 128.50,
            monthExpense: 3680.00,
            transactionCount: 42,
            topCategory: "餐饮"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MoneyBuddyEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoneyBuddyEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> MoneyBuddyEntry {
        // Load from shared UserDefaults (App Group)
        let defaults = UserDefaults(suiteName: "group.com.moneybuddy.app")

        let todayExpense = Decimal(defaults?.double(forKey: "widget_today_expense") ?? 0)
        let monthExpense = Decimal(defaults?.double(forKey: "widget_month_expense") ?? 0)
        let transactionCount = defaults?.integer(forKey: "widget_transaction_count") ?? 0
        let topCategory = defaults?.string(forKey: "widget_top_category")

        return MoneyBuddyEntry(
            date: Date(),
            todayExpense: todayExpense,
            monthExpense: monthExpense,
            transactionCount: transactionCount,
            topCategory: topCategory
        )
    }
}

/// Small widget view
struct SmallWidgetView: View {
    let entry: MoneyBuddyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.blue)
                Text("MoneyBuddy")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            Text("今日支出")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("¥\(entry.todayExpense as NSDecimalNumber, formatter: currencyFormatter)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Spacer()

            Text("本月 ¥\(entry.monthExpense as NSDecimalNumber, formatter: currencyFormatter)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

/// Medium widget view
struct MediumWidgetView: View {
    let entry: MoneyBuddyEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Today's expense
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.blue)
                    Text("MoneyBuddy")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                Text("今日支出")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("¥\(entry.todayExpense as NSDecimalNumber, formatter: currencyFormatter)")
                    .font(.title)
                    .fontWeight(.bold)
            }

            Divider()

            // Right: Stats
            VStack(alignment: .leading, spacing: 12) {
                StatRow(title: "本月支出", value: "¥\(entry.monthExpense)")
                StatRow(title: "记账笔数", value: "\(entry.transactionCount)笔")
                if let category = entry.topCategory {
                    StatRow(title: "最多类别", value: category)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

/// Stat row for medium widget
struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

/// Main widget configuration
struct MoneyBuddyWidget: Widget {
    let kind: String = "MoneyBuddyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoneyBuddyProvider()) { entry in
            if #available(iOS 17.0, *) {
                MoneyBuddyWidgetEntryView(entry: entry)
            } else {
                MoneyBuddyWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("MoneyBuddy")
        .description("查看今日和本月支出概览")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Widget entry view
struct MoneyBuddyWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MoneyBuddyEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Data Sync

/// Service to sync data with widget
final class WidgetDataSync {
    static let shared = WidgetDataSync()

    private let defaults = UserDefaults(suiteName: "group.com.moneybuddy.app")

    private init() {}

    /// Update widget data
    func update(todayExpense: Decimal, monthExpense: Decimal, transactionCount: Int, topCategory: String?) {
        defaults?.set(Double(truncating: todayExpense as NSDecimalNumber), forKey: "widget_today_expense")
        defaults?.set(Double(truncating: monthExpense as NSDecimalNumber), forKey: "widget_month_expense")
        defaults?.set(transactionCount, forKey: "widget_transaction_count")
        defaults?.set(topCategory, forKey: "widget_top_category")

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "MoneyBuddyWidget")
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    MoneyBuddyWidget()
} timeline: {
    MoneyBuddyEntry(date: Date(), todayExpense: 128.50, monthExpense: 3680.00, transactionCount: 42, topCategory: "餐饮")
}

#Preview(as: .systemMedium) {
    MoneyBuddyWidget()
} timeline: {
    MoneyBuddyEntry(date: Date(), todayExpense: 128.50, monthExpense: 3680.00, transactionCount: 42, topCategory: "餐饮")
}
