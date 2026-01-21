//
//  TransactionDetailView.swift
//  MoneyBuddy
//
//  Transaction detail and edit view
//

import SwiftUI

/// Transaction detail view
struct TransactionDetailView: View {
    /// Transaction to display/edit
    @Bindable var transaction: Transaction

    /// Transaction store
    @ObservedObject var store: TransactionStore

    /// Delete callback
    let onDelete: () -> Void

    /// Edit mode
    @State private var isEditing: Bool = false

    /// Edited values
    @State private var editAmount: String = ""
    @State private var editMerchant: String = ""
    @State private var editCategory: Category = .other
    @State private var editType: TransactionType = .expense
    @State private var editNote: String = ""

    /// Show delete confirmation
    @State private var showDeleteAlert: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Amount section
                Section {
                    if isEditing {
                        HStack {
                            Text("¥")
                                .foregroundColor(.secondary)
                            TextField("金额", text: $editAmount)
                                .keyboardType(.decimalPad)
                        }
                    } else {
                        HStack {
                            Text("金额")
                            Spacer()
                            Text(transaction.formattedAmount)
                                .foregroundColor(transaction.type == .expense ? .primary : .green)
                        }
                    }
                }

                // Type section
                Section {
                    if isEditing {
                        Picker("类型", selection: $editType) {
                            ForEach(TransactionType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                    } else {
                        HStack {
                            Text("类型")
                            Spacer()
                            Text(transaction.type.rawValue)
                        }
                    }
                }

                // Category section
                Section {
                    if isEditing {
                        Picker("分类", selection: $editCategory) {
                            ForEach(Category.allCases) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }
                    } else {
                        HStack {
                            Text("分类")
                            Spacer()
                            Label(transaction.category.rawValue, systemImage: transaction.category.icon)
                        }
                    }
                }

                // Merchant section
                Section {
                    if isEditing {
                        TextField("商家名称", text: $editMerchant)
                    } else {
                        HStack {
                            Text("商家")
                            Spacer()
                            Text(transaction.merchant ?? "-")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Note section
                Section {
                    if isEditing {
                        TextField("备注", text: $editNote)
                    } else {
                        HStack {
                            Text("备注")
                            Spacer()
                            Text(transaction.note ?? "-")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Info section
                Section("详情") {
                    HStack {
                        Text("日期")
                        Spacer()
                        Text(transaction.formattedDate)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("来源")
                        Spacer()
                        Label(transaction.source.rawValue, systemImage: transaction.source.icon)
                            .foregroundColor(.secondary)
                    }

                    if let bankName = transaction.bankName {
                        HStack {
                            Text("银行")
                            Spacer()
                            Text(bankName)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let cardSuffix = transaction.cardSuffix {
                        HStack {
                            Text("卡号")
                            Spacer()
                            Text("****\(cardSuffix)")
                                .foregroundColor(.secondary)
                        }
                    }

                    if transaction.aiClassified {
                        HStack {
                            Text("分类方式")
                            Spacer()
                            Label("AI智能分类", systemImage: "sparkles")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Delete button
                if !isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("删除记录")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("交易详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("取消") {
                            isEditing = false
                        }
                    } else {
                        Button("关闭") {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("保存") {
                            saveChanges()
                        }
                    } else {
                        Button("编辑") {
                            startEditing()
                        }
                    }
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("删除", role: .destructive) {
                    store.delete(transaction)
                    dismiss()
                    onDelete()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除这条记录吗？此操作无法撤销。")
            }
        }
    }

    /// Start editing mode
    private func startEditing() {
        editAmount = "\(transaction.amount)"
        editMerchant = transaction.merchant ?? ""
        editCategory = transaction.category
        editType = transaction.type
        editNote = transaction.note ?? ""
        isEditing = true
    }

    /// Save changes
    private func saveChanges() {
        if let amount = Decimal(string: editAmount) {
            transaction.amount = amount
        }
        transaction.merchant = editMerchant.isEmpty ? nil : editMerchant
        transaction.category = editCategory
        transaction.type = editType
        transaction.note = editNote.isEmpty ? nil : editNote

        store.update(transaction)
        isEditing = false
    }
}

#Preview {
    TransactionDetailView(
        transaction: Transaction(
            amount: 35.50,
            type: .expense,
            category: .food,
            merchant: "星巴克咖啡"
        ),
        store: TransactionStore(modelContext: try! ModelContainer(for: Transaction.self).mainContext),
        onDelete: {}
    )
}
