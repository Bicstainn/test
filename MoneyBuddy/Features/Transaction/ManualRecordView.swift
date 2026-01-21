//
//  ManualRecordView.swift
//  MoneyBuddy
//
//  Manual transaction entry form
//

import SwiftUI
import SwiftData

/// Manual record entry view
struct ManualRecordView: View {
    /// Transaction store
    @ObservedObject var store: TransactionStore

    /// Form values
    @State private var amount: String = ""
    @State private var type: TransactionType = .expense
    @State private var category: Category = .other
    @State private var merchant: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()

    /// Keyboard focus
    @FocusState private var isAmountFocused: Bool

    /// Show success feedback
    @State private var showSuccess: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Amount input with calculator-style display
                Section {
                    VStack(spacing: 8) {
                        Text(type == .expense ? "支出" : "收入")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("¥")
                                .font(.title)
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $amount)
                                .font(.system(size: 48, weight: .medium))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .focused($isAmountFocused)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)

                // Type selector
                Section {
                    Picker("类型", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _, newType in
                        // Auto-select income category when switching to income
                        if newType == .income && category != .income {
                            category = .income
                        } else if newType == .expense && category == .income {
                            category = .other
                        }
                    }
                }

                // Category selection
                Section("分类") {
                    categoryGrid
                }

                // Merchant and note
                Section("详情") {
                    TextField("商家名称（可选）", text: $merchant)

                    TextField("备注（可选）", text: $note)

                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                // Save button
                Section {
                    Button(action: saveTransaction) {
                        HStack {
                            Spacer()
                            if showSuccess {
                                Label("已保存", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Text("保存记录")
                            }
                            Spacer()
                        }
                    }
                    .disabled(amount.isEmpty || Decimal(string: amount) == nil)
                }
            }
            .navigationTitle("手动记账")
            .onAppear {
                isAmountFocused = true
            }
        }
    }

    /// Category selection grid
    private var categoryGrid: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]

        let categories = type == .expense
            ? Category.allCases.filter { $0 != .income }
            : [Category.income]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories) { cat in
                CategoryButton(
                    category: cat,
                    isSelected: category == cat,
                    action: { category = cat }
                )
            }
        }
        .padding(.vertical, 8)
    }

    /// Save the transaction
    private func saveTransaction() {
        guard let decimalAmount = Decimal(string: amount), decimalAmount > 0 else {
            return
        }

        let transaction = Transaction(
            amount: decimalAmount,
            type: type,
            category: category,
            merchant: merchant.isEmpty ? nil : merchant,
            note: note.isEmpty ? nil : note,
            date: date,
            source: .manual,
            paymentSource: .unknown,
            aiClassified: false
        )

        store.add(transaction)

        // Show success feedback
        withAnimation {
            showSuccess = true
        }

        // Reset form after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            resetForm()
        }
    }

    /// Reset form to initial state
    private func resetForm() {
        withAnimation {
            amount = ""
            merchant = ""
            note = ""
            date = Date()
            showSuccess = false
            isAmountFocused = true
        }
    }
}

#Preview {
    ManualRecordView(store: TransactionStore(modelContext: try! ModelContainer(for: Transaction.self).mainContext))
}
