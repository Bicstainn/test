//
//  CSVService.swift
//  MoneyBuddy
//
//  CSV import and export service
//

import Foundation
import UniformTypeIdentifiers

/// CSV import/export errors
enum CSVError: Error, LocalizedError {
    case invalidFormat
    case missingRequiredColumn(String)
    case parseError(row: Int, column: String)
    case exportFailed
    case importFailed

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "无效的CSV格式"
        case .missingRequiredColumn(let column):
            return "缺少必需列：\(column)"
        case .parseError(let row, let column):
            return "第\(row)行的\(column)列解析失败"
        case .exportFailed:
            return "导出失败"
        case .importFailed:
            return "导入失败"
        }
    }
}

/// CSV import result
struct CSVImportResult {
    let successCount: Int
    let failedCount: Int
    let errors: [String]
}

/// CSV service for data import/export
final class CSVService {
    /// Shared instance
    static let shared = CSVService()

    /// Required columns for import
    private let requiredColumns = ["金额", "类型"]

    /// Optional columns
    private let optionalColumns = ["日期", "分类", "商家", "备注", "来源"]

    private init() {}

    // MARK: - Export

    /// Export transactions to CSV string
    /// - Parameter transactions: Transactions to export
    /// - Returns: CSV formatted string
    func exportToCSV(_ transactions: [Transaction]) -> String {
        var csv = "日期,类型,金额,分类,商家,备注,来源,银行,卡号\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for tx in transactions {
            let date = dateFormatter.string(from: tx.date)
            let type = tx.type.rawValue
            let amount = "\(tx.amount)"
            let category = tx.category.rawValue
            let merchant = escapeCSV(tx.merchant ?? "")
            let note = escapeCSV(tx.note ?? "")
            let source = tx.source.rawValue
            let bank = tx.bankName ?? ""
            let card = tx.cardSuffix ?? ""

            csv += "\(date),\(type),\(amount),\(category),\(merchant),\(note),\(source),\(bank),\(card)\n"
        }

        return csv
    }

    /// Export transactions to file URL
    /// - Parameters:
    ///   - transactions: Transactions to export
    ///   - filename: Output filename
    /// - Returns: URL of exported file
    func exportToFile(_ transactions: [Transaction], filename: String = "MoneyBuddy_Export") throws -> URL {
        let csv = exportToCSV(transactions)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(filename)_\(timestamp).csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw CSVError.exportFailed
        }
    }

    // MARK: - Import

    /// Import transactions from CSV string
    /// - Parameter csv: CSV string content
    /// - Returns: Array of parsed transactions
    func importFromCSV(_ csv: String) throws -> [ParsedTransaction] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard lines.count > 1 else {
            throw CSVError.invalidFormat
        }

        // Parse header
        let header = parseCSVLine(lines[0])
        let columnMap = Dictionary(uniqueKeysWithValues: header.enumerated().map { ($1, $0) })

        // Validate required columns
        for required in requiredColumns {
            if columnMap[required] == nil {
                throw CSVError.missingRequiredColumn(required)
            }
        }

        var results: [ParsedTransaction] = []

        // Parse data rows
        for (index, line) in lines.dropFirst().enumerated() {
            let values = parseCSVLine(line)

            var parsed = ParsedTransaction()

            // Amount (required)
            if let amountIndex = columnMap["金额"],
               amountIndex < values.count,
               let amount = Decimal(string: values[amountIndex]) {
                parsed.amount = amount
            } else {
                throw CSVError.parseError(row: index + 2, column: "金额")
            }

            // Type (required)
            if let typeIndex = columnMap["类型"],
               typeIndex < values.count {
                let typeValue = values[typeIndex]
                parsed.isExpense = (typeValue == "支出" || typeValue == "expense")
            }

            // Date (optional)
            if let dateIndex = columnMap["日期"],
               dateIndex < values.count {
                parsed.date = parseDate(values[dateIndex])
            }

            // Category (optional)
            if let categoryIndex = columnMap["分类"],
               categoryIndex < values.count {
                parsed.category = Category(rawValue: values[categoryIndex])
            }

            // Merchant (optional)
            if let merchantIndex = columnMap["商家"],
               merchantIndex < values.count {
                parsed.merchant = values[merchantIndex].isEmpty ? nil : values[merchantIndex]
            }

            // Note (optional)
            if let noteIndex = columnMap["备注"],
               noteIndex < values.count {
                parsed.note = values[noteIndex].isEmpty ? nil : values[noteIndex]
            }

            results.append(parsed)
        }

        return results
    }

    /// Import from file URL
    /// - Parameter url: CSV file URL
    /// - Returns: Array of parsed transactions
    func importFromFile(_ url: URL) throws -> [ParsedTransaction] {
        let csv = try String(contentsOf: url, encoding: .utf8)
        return try importFromCSV(csv)
    }

    // MARK: - Helpers

    /// Parse a single CSV line
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }

        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }

    /// Escape string for CSV
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }

    /// Parse date from various formats
    private func parseDate(_ string: String) -> Date? {
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd",
            "MM/dd/yyyy"
        ]

        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }
}

// MARK: - Export View

import SwiftUI

/// Export options view
struct ExportView: View {
    @ObservedObject var store: TransactionStore

    @State private var exportRange: ExportRange = .all
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    enum ExportRange: String, CaseIterable {
        case all = "全部数据"
        case thisMonth = "本月"
        case thisYear = "今年"
        case last30Days = "最近30天"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("导出范围") {
                    Picker("范围", selection: $exportRange) {
                        ForEach(ExportRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("将导出 \(filteredTransactions.count) 条记录")
                        .foregroundColor(.secondary)
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                            } else {
                                Label("导出CSV", systemImage: "square.and.arrow.up")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isExporting || filteredTransactions.isEmpty)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("导出数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()

        switch exportRange {
        case .all:
            return store.allTransactions
        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return store.allTransactions.filter { $0.date >= startOfMonth }
        case .thisYear:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return store.allTransactions.filter { $0.date >= startOfYear }
        case .last30Days:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
            return store.allTransactions.filter { $0.date >= thirtyDaysAgo }
        }
    }

    private func exportData() {
        isExporting = true
        errorMessage = nil

        do {
            let url = try CSVService.shared.exportToFile(filteredTransactions)
            exportedURL = url
            showShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isExporting = false
    }
}

/// Share sheet for exporting
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Import View

/// Import options view
struct ImportView: View {
    @ObservedObject var store: TransactionStore

    @State private var isImporting = false
    @State private var showFilePicker = false
    @State private var importResult: CSVImportResult?
    @State private var parsedTransactions: [ParsedTransaction] = []
    @State private var showConfirmation = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("选择CSV文件", systemImage: "doc.badge.plus")
                    }
                } footer: {
                    Text("支持的列：日期, 类型, 金额, 分类, 商家, 备注")
                }

                if !parsedTransactions.isEmpty {
                    Section("预览") {
                        Text("已解析 \(parsedTransactions.count) 条记录")

                        ForEach(parsedTransactions.prefix(5), id: \.amount) { tx in
                            HStack {
                                Text(tx.merchant ?? "未知商家")
                                Spacer()
                                Text("¥\(tx.amount ?? 0)")
                                    .foregroundColor(tx.isExpense ? .primary : .green)
                            }
                        }

                        if parsedTransactions.count > 5 {
                            Text("...还有 \(parsedTransactions.count - 5) 条")
                                .foregroundColor(.secondary)
                        }
                    }

                    Section {
                        Button {
                            confirmImport()
                        } label: {
                            HStack {
                                Spacer()
                                Label("确认导入", systemImage: "square.and.arrow.down")
                                Spacer()
                            }
                        }
                    }
                }

                if let result = importResult {
                    Section("导入结果") {
                        Text("成功：\(result.successCount) 条")
                            .foregroundColor(.green)
                        if result.failedCount > 0 {
                            Text("失败：\(result.failedCount) 条")
                                .foregroundColor(.red)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("导入数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "无法访问文件"
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            do {
                parsedTransactions = try CSVService.shared.importFromFile(url)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
                parsedTransactions = []
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func confirmImport() {
        var successCount = 0
        var failedCount = 0

        for parsed in parsedTransactions {
            guard let amount = parsed.amount else {
                failedCount += 1
                continue
            }

            let transaction = Transaction(
                amount: amount,
                type: parsed.isExpense ? .expense : .income,
                category: parsed.category ?? .other,
                merchant: parsed.merchant,
                note: parsed.note,
                date: parsed.date ?? Date(),
                source: .csv
            )

            store.add(transaction)
            successCount += 1
        }

        importResult = CSVImportResult(
            successCount: successCount,
            failedCount: failedCount,
            errors: []
        )

        parsedTransactions = []
    }
}
