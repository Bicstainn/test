//
//  WeeklyReportView.swift
//  MoneyBuddy
//
//  AI-generated weekly spending report
//

import SwiftUI

/// AI weekly report view
struct WeeklyReportView: View {
    /// Transaction store
    @ObservedObject var store: TransactionStore

    /// Report content
    @State private var reportContent: String = ""

    /// Loading state
    @State private var isLoading: Bool = true

    /// Error message
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Report content
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else {
                        reportSection
                    }

                    // Statistics summary
                    statisticsSummary
                }
                .padding()
            }
            .navigationTitle("AI周报")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .task {
                await generateReport()
            }
        }
    }

    /// Header section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text("本周消费分析")
                .font(.title2)
                .fontWeight(.bold)

            Text(dateRangeString)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    /// Loading view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在生成分析报告...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    /// Error view
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("重试") {
                Task {
                    await generateReport()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    /// Report content section
    private var reportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(reportContent)
                .font(.body)
                .lineSpacing(6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    /// Statistics summary
    private var statisticsSummary: some View {
        let transactions = store.currentWeekTransactions
        let stats = store.statistics(for: transactions)

        return VStack(spacing: 16) {
            Text("数据概览")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                StatItem(title: "总支出", value: "¥\(stats.totalExpense)", color: .red)
                StatItem(title: "总收入", value: "¥\(stats.totalIncome)", color: .green)
                StatItem(title: "笔数", value: "\(stats.transactionCount)", color: .blue)
            }

            // Top categories
            if !stats.categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("支出分布")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(stats.categoryBreakdown.prefix(5), id: \.category) { item in
                        HStack {
                            Image(systemName: item.category.icon)
                                .foregroundColor(Color(hex: item.category.colorHex))
                                .frame(width: 24)
                            Text(item.category.rawValue)
                            Spacer()
                            Text("¥\(item.amount)")
                                .foregroundColor(.secondary)
                            Text("\(Int(item.percentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    /// Date range string
    private var dateRangeString: String {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!

        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"

        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }

    /// Generate AI report
    private func generateReport() async {
        isLoading = true
        errorMessage = nil

        let transactions = store.currentWeekTransactions

        if transactions.isEmpty {
            reportContent = "本周暂无消费记录。开始记账后，这里会生成智能分析报告。"
            isLoading = false
            return
        }

        do {
            reportContent = try await DeepSeekService.shared.generateWeeklyReport(transactions)
            isLoading = false
        } catch let error as DeepSeekError {
            errorMessage = error.localizedDescription
            isLoading = false
        } catch {
            errorMessage = "生成报告失败，请稍后重试"
            isLoading = false
        }
    }
}

/// Statistics item
struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WeeklyReportView(store: TransactionStore(modelContext: try! ModelContainer(for: Transaction.self).mainContext))
}
