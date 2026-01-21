//
//  PaymentSource.swift
//  MoneyBuddy
//
//  Payment platform enumeration
//

import Foundation

/// Payment platform source
enum PaymentSource: String, Codable, CaseIterable {
    case wechat = "微信支付"
    case alipay = "支付宝"
    case bank = "银行卡"
    case cash = "现金"
    case unknown = "未知"

    /// Icon for payment source
    var icon: String {
        switch self {
        case .wechat: return "message.circle.fill"
        case .alipay: return "a.circle.fill"
        case .bank: return "creditcard.fill"
        case .cash: return "banknote.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}
