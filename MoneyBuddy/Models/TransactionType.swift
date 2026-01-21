//
//  TransactionType.swift
//  MoneyBuddy
//
//  Transaction type enumeration
//

import Foundation

/// Transaction type: income or expense
enum TransactionType: String, Codable, CaseIterable {
    case income = "收入"
    case expense = "支出"

    /// Icon for transaction type
    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }

    /// Sign for display (+ or -)
    var sign: String {
        switch self {
        case .income: return "+"
        case .expense: return "-"
        }
    }
}
