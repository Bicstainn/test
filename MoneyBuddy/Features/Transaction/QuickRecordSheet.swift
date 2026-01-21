//
//  QuickRecordSheet.swift
//  MoneyBuddy
//
//  Quick confirmation sheet for parsed transactions
//

import SwiftUI

/// Quick record confirmation sheet
struct QuickRecordSheet: View {
    /// Parsed transaction data
    let parsed: ParsedTransaction

    /// Transaction store
    @ObservedObject var store: TransactionStore

    /// Dismiss callback
    let onDismiss: () -> Void

    /// Editable amount
    @State private var amount: String = ""

    /// Editable merchant
    @State private var merchant: String = ""

    /// Selected category
    @State private var category: Category = .other

    /// Transaction type
    @State private var type: TransactionType = .expense

    /// Note
    @State private var note: String = ""

    /// Is classifying with AI
    @State private var isClassifying: Bool = false

    /// Classification source indicator
    @State private var classificationSource: ClassificationSource = .defaultValue

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Amount section
                Section {
                    HStack {
                        Text("¥")
                            .font(.title)
                            .foregroundColor(.secondary)
                        TextField("金额", text: $amount)
                            .font(.title)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("交易金额")
                }

                // Transaction type
                Section {
                    Picker("类型", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Merchant section
                Section {
                    TextField("商家名称", text: $merchant)
                        .onChange(of: merchant) { _, newValue in
                            if !newValue.isEmpty {
                                classifyMerchant(newValue)
                            }
                        }
                } header: {
                    Text("商家")
                }

                // Category section
                Section {
                    categoryGrid
                } header: {
                    HStack {
                        Text("分类")
                        Spacer()
                        if isClassifying {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if classificationSource == .ai {
                            Text("AI推荐")
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else if classificationSource == .keyword {
                            Text("自动识别")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                // Note section
                Section {
                    TextField("备注（可选）", text: $note)
                } header: {
                    Text("备注")
                }

                // Source info
                if let source = parsed.paymentSource, source != .unknown {
                    Section {
                        HStack {
                            Image(systemName: source.icon)
                            Text(source.rawValue)
                        }
                        .foregroundColor(.secondary)
                    } header: {
                        Text("来源")
                    }
                }
            }
            .navigationTitle("确认记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTransaction()
                    }
                    .disabled(amount.isEmpty)
                }
            }
            .onAppear {
                initializeFromParsed()
            }
        }
    }

    /// Category selection grid
    private var categoryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(Category.allCases) { cat in
                CategoryButton(
                    category: cat,
                    isSelected: category == cat,
                    action: { category = cat }
                )
            }
        }
        .padding(.vertical, 8)
    }

    /// Initialize fields from parsed data
    private func initializeFromParsed() {
        if let parsedAmount = parsed.amount {
            amount = "\(parsedAmount)"
        }
        merchant = parsed.merchant ?? ""
        type = parsed.type

        // Trigger classification if merchant exists
        if !merchant.isEmpty {
            classifyMerchant(merchant)
        }
    }

    /// Classify merchant and update category
    private func classifyMerchant(_ merchantName: String) {
        // Try local classification first
        let localResult = CategoryEngine.shared.classifyLocal(merchantName)
        if localResult.source != .defaultValue {
            category = localResult.category
            classificationSource = localResult.source
            return
        }

        // Try AI classification
        isClassifying = true
        Task {
            let result = await CategoryEngine.shared.classify(merchantName, useAI: true)
            await MainActor.run {
                category = result.category
                classificationSource = result.source
                isClassifying = false
            }
        }
    }

    /// Save the transaction
    private func saveTransaction() {
        guard let decimalAmount = Decimal(string: amount) else { return }

        var updatedParsed = parsed
        updatedParsed.amount = decimalAmount
        updatedParsed.merchant = merchant.isEmpty ? nil : merchant
        updatedParsed.type = type

        // Determine data source
        let source: DataSource = parsed.bankName != nil ? .sms : .ocr

        store.createFromParsed(updatedParsed, category: category, source: source)

        // Cache correction if user changed category
        if !merchant.isEmpty && classificationSource != .cached {
            CategoryEngine.shared.cacheCorrection(merchant: merchant, category: category)
        }

        dismiss()
        onDismiss()
    }
}

/// Category selection button
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickRecordSheet(
        parsed: ParsedTransaction(
            amount: 25.50,
            merchant: "星巴克",
            type: .expense,
            paymentSource: .wechat
        ),
        store: TransactionStore(modelContext: try! ModelContainer(for: Transaction.self).mainContext),
        onDismiss: {}
    )
}
