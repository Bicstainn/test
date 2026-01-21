//
//  Category.swift
//  MoneyBuddy
//
//  Transaction category enumeration
//

import Foundation

/// Transaction categories for expense/income classification
enum Category: String, Codable, CaseIterable, Identifiable {
    case food = "餐饮"
    case transport = "交通"
    case shopping = "购物"
    case entertainment = "娱乐"
    case housing = "住房"
    case medical = "医疗"
    case education = "教育"
    case income = "收入"
    case other = "其他"

    var id: String { rawValue }

    /// Icon for each category
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "cart.fill"
        case .entertainment: return "gamecontroller.fill"
        case .housing: return "house.fill"
        case .medical: return "cross.case.fill"
        case .education: return "book.fill"
        case .income: return "dollarsign.circle.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    /// Color for each category (as hex string for SwiftUI)
    var colorHex: String {
        switch self {
        case .food: return "#FF6B6B"
        case .transport: return "#4ECDC4"
        case .shopping: return "#FFE66D"
        case .entertainment: return "#95E1D3"
        case .housing: return "#F38181"
        case .medical: return "#AA96DA"
        case .education: return "#6C5CE7"
        case .income: return "#00B894"
        case .other: return "#636E72"
        }
    }
}
