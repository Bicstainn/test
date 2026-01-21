//
//  BankSMSParser.swift
//  MoneyBuddy
//
//  Bank SMS message parser
//

import Foundation

/// Bank SMS sender identification
enum BankSMS: String, CaseIterable {
    case icbc = "95588"      // 工商银行
    case ccb = "95533"       // 建设银行
    case abc = "95599"       // 农业银行
    case boc = "95566"       // 中国银行
    case cmb = "95555"       // 招商银行
    case comm = "95559"      // 交通银行
    case citic = "95558"     // 中信银行
    case spdb = "95528"      // 浦发银行
    case ceb = "95595"       // 光大银行
    case pab = "95511"       // 平安银行

    /// Bank display name
    var bankName: String {
        switch self {
        case .icbc: return "工商银行"
        case .ccb: return "建设银行"
        case .abc: return "农业银行"
        case .boc: return "中国银行"
        case .cmb: return "招商银行"
        case .comm: return "交通银行"
        case .citic: return "中信银行"
        case .spdb: return "浦发银行"
        case .ceb: return "光大银行"
        case .pab: return "平安银行"
        }
    }

    /// Detect bank from SMS content
    static func detect(from text: String) -> BankSMS? {
        let bankKeywords: [BankSMS: [String]] = [
            .icbc: ["工商银行", "工行", "ICBC"],
            .ccb: ["建设银行", "建行", "CCB"],
            .abc: ["农业银行", "农行", "ABC"],
            .boc: ["中国银行", "中行", "BOC"],
            .cmb: ["招商银行", "招行", "CMB"],
            .comm: ["交通银行", "交行", "COMM"],
            .citic: ["中信银行", "中信", "CITIC"],
            .spdb: ["浦发银行", "浦发", "SPDB"],
            .ceb: ["光大银行", "光大", "CEB"],
            .pab: ["平安银行", "平安", "PAB"]
        ]

        for (bank, keywords) in bankKeywords {
            for keyword in keywords {
                if text.contains(keyword) {
                    return bank
                }
            }
        }
        return nil
    }
}

/// SMS parsing template
struct SMSTemplate {
    let amountPattern: String
    let merchantPattern: String?
    let cardPattern: String?

    init(amountPattern: String, merchantPattern: String? = nil, cardPattern: String? = nil) {
        self.amountPattern = amountPattern
        self.merchantPattern = merchantPattern
        self.cardPattern = cardPattern
    }
}

/// Parsed SMS result
struct ParsedSMS {
    var amount: Decimal?
    var merchant: String?
    var bankName: String?
    var cardSuffix: String?
    var isExpense: Bool = true
    var rawText: String?
}

/// Bank SMS parser
final class BankSMSParser {
    /// Bank-specific templates
    private let templates: [BankSMS: SMSTemplate] = [
        .icbc: SMSTemplate(
            amountPattern: "支出\\(人民币\\)([0-9]+\\.?[0-9]*)元",
            merchantPattern: "在(.+?)消费",
            cardPattern: "尾号(\\d{4})"
        ),
        .ccb: SMSTemplate(
            amountPattern: "支出人民币([0-9]+\\.?[0-9]*)",
            merchantPattern: "(微信支付|支付宝|云闪付)",
            cardPattern: "尾号(\\d{4})"
        ),
        .cmb: SMSTemplate(
            amountPattern: "消费.*?([0-9]+\\.?[0-9]*)元",
            merchantPattern: "在(.+?)消费",
            cardPattern: "尾号(\\d{4})"
        ),
        .abc: SMSTemplate(
            amountPattern: "消费([0-9]+\\.?[0-9]*)元",
            merchantPattern: "在(.+?)消费",
            cardPattern: "尾号(\\d{4})"
        ),
        .boc: SMSTemplate(
            amountPattern: "支出([0-9]+\\.?[0-9]*)元",
            merchantPattern: "在(.+?)消费",
            cardPattern: "(\\d{4})卡"
        ),
        .comm: SMSTemplate(
            amountPattern: "消费([0-9]+\\.?[0-9]*)元",
            merchantPattern: "在(.+?)消费",
            cardPattern: "尾号(\\d{4})"
        ),
        .citic: SMSTemplate(
            amountPattern: "消费([0-9]+\\.?[0-9]*)元",
            merchantPattern: "在(.+?)消费",
            cardPattern: "尾号(\\d{4})"
        ),
        .spdb: SMSTemplate(
            amountPattern: "支出([0-9]+\\.?[0-9]*)元",
            merchantPattern: "在(.+?)消费",
            cardPattern: "尾号(\\d{4})"
        ),
        .ceb: SMSTemplate(
            amountPattern: "消费([0-9]+\\.?[0-9]*)元",
            merchantPattern: "在(.+?)消费",
            cardPattern: "尾号(\\d{4})"
        ),
        .pab: SMSTemplate(
            amountPattern: "支出([0-9]+\\.?[0-9]*)元",
            merchantPattern: "在(.+?)消费",
            cardPattern: "尾号(\\d{4})"
        )
    ]

    /// Generic patterns for unknown banks
    private let genericPatterns = SMSTemplate(
        amountPattern: "(?:支出|消费|扣款).*?([0-9]+\\.?[0-9]*)元?|人民币-?([0-9]+\\.?[0-9]*)",
        merchantPattern: "在(.+?)(?:消费|支付|扣款)",
        cardPattern: "尾号(\\d{4})"
    )

    /// Parse SMS text
    /// - Parameter text: Raw SMS content
    /// - Returns: Parsed SMS data or nil if not a valid transaction SMS
    func parse(_ text: String) -> ParsedSMS? {
        var result = ParsedSMS()
        result.rawText = text

        // Detect bank
        let bank = BankSMS.detect(from: text)
        result.bankName = bank?.bankName

        // Get appropriate template
        let template = bank.flatMap { templates[$0] } ?? genericPatterns

        // Extract amount
        result.amount = extractAmount(from: text, pattern: template.amountPattern)

        // If no amount found, this is not a transaction SMS
        guard result.amount != nil else {
            return nil
        }

        // Extract merchant
        if let merchantPattern = template.merchantPattern {
            result.merchant = extractFirst(text, pattern: merchantPattern)
        }

        // Extract card suffix
        if let cardPattern = template.cardPattern {
            result.cardSuffix = extractFirst(text, pattern: cardPattern)
        }

        // Detect income vs expense
        result.isExpense = !isIncomeSMS(text)

        return result
    }

    /// Extract amount from text
    private func extractAmount(from text: String, pattern: String) -> Decimal? {
        guard let match = extractFirst(text, pattern: pattern) else {
            return nil
        }
        return Decimal(string: match)
    }

    /// Check if SMS indicates income
    private func isIncomeSMS(_ text: String) -> Bool {
        let incomeKeywords = ["收入", "到账", "转入", "存入", "入账"]
        return incomeKeywords.contains { text.contains($0) }
    }

    /// Helper to extract first regex capture group
    private func extractFirst(_ text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        // Return first capture group
        let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range(at: 0)
        guard let swiftRange = Range(captureRange, in: text) else {
            return nil
        }

        return String(text[swiftRange])
    }
}
