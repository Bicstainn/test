//
//  DataSource.swift
//  MoneyBuddy
//
//  Data source enumeration
//

import Foundation

/// Source of transaction data
enum DataSource: String, Codable, CaseIterable {
    case ocr = "屏幕识别"
    case sms = "银行短信"
    case csv = "账单导入"
    case manual = "手动录入"

    /// Icon for each data source
    var icon: String {
        switch self {
        case .ocr: return "camera.viewfinder"
        case .sms: return "message.fill"
        case .csv: return "doc.text.fill"
        case .manual: return "square.and.pencil"
        }
    }
}
