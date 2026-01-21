//
//  Transaction.swift
//  MoneyBuddy
//
//  Main transaction data model using SwiftData
//

import Foundation
import SwiftData

/// Main transaction model for SwiftData persistence
@Model
final class Transaction {
    /// Unique identifier
    var id: UUID

    /// Transaction amount (always positive, use type for direction)
    var amount: Decimal

    /// Income or expense
    var type: TransactionType

    /// Category classification
    var category: Category

    /// Merchant or payer name
    var merchant: String?

    /// User note
    var note: String?

    /// Transaction date
    var date: Date

    /// Data source (OCR/SMS/CSV/Manual)
    var source: DataSource

    /// Bank name if from SMS
    var bankName: String?

    /// Last 4 digits of card
    var cardSuffix: String?

    /// Payment platform
    var paymentSource: PaymentSource

    /// Whether category was set by AI
    var aiClassified: Bool

    /// Record creation timestamp
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Decimal,
        type: TransactionType = .expense,
        category: Category = .other,
        merchant: String? = nil,
        note: String? = nil,
        date: Date = Date(),
        source: DataSource = .manual,
        bankName: String? = nil,
        cardSuffix: String? = nil,
        paymentSource: PaymentSource = .unknown,
        aiClassified: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.category = category
        self.merchant = merchant
        self.note = note
        self.date = date
        self.source = source
        self.bankName = bankName
        self.cardSuffix = cardSuffix
        self.paymentSource = paymentSource
        self.aiClassified = aiClassified
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension Transaction {
    /// Formatted amount with sign
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let value = formatter.string(from: amount as NSDecimalNumber) ?? "¥0.00"
        return type == .expense ? "-\(value)" : "+\(value)"
    }

    /// Display title (merchant or category)
    var displayTitle: String {
        merchant ?? category.rawValue
    }

    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}
