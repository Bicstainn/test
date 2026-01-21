//
//  TransactionParser.swift
//  MoneyBuddy
//
//  OCR text parser for payment screenshots
//

import Foundation

/// Intermediate structure for parsed transaction data
struct ParsedTransaction {
    var amount: Decimal?
    var merchant: String?
    var type: TransactionType = .expense
    var paymentSource: PaymentSource = .unknown
    var bankName: String?
    var cardSuffix: String?
    var rawText: String?
    var confidence: Double = 0.0

    /// Whether the parsed result is valid for saving
    var isValid: Bool {
        amount != nil && amount! > 0
    }
}

/// Parser for OCR text from payment screenshots
struct TransactionParser {
    /// Amount extraction patterns (ordered by priority)
    private let amountPatterns: [String] = [
        "¥\\s*([0-9]+\\.?[0-9]*)",           // ¥123.45
        "￥\\s*([0-9]+\\.?[0-9]*)",           // ￥123.45
        "支付金额.*?([0-9]+\\.[0-9]{2})",    // 支付金额 123.45
        "付款金额.*?([0-9]+\\.[0-9]{2})",    // 付款金额 123.45
        "实付.*?([0-9]+\\.[0-9]{2})",        // 实付 123.45
        "([0-9]+\\.[0-9]{2})\\s*元",         // 123.45 元
        "([0-9]+)\\s*元"                     // 123 元
    ]

    /// Merchant extraction patterns
    private let merchantPatterns: [String] = [
        "收款方[：:]\\s*(.+?)(?:\\n|$)",      // 收款方：商家名
        "付款给[：:]\\s*(.+?)(?:\\n|$)",      // 付款给：商家名
        "商户名称[：:]\\s*(.+?)(?:\\n|$)",    // 商户名称：商家名
        "商家[：:]\\s*(.+?)(?:\\n|$)",        // 商家：商家名
        "向(.+?)付款",                        // 向商家付款
        "给(.+?)支付"                         // 给商家支付
    ]

    /// Parse OCR text into transaction data
    /// - Parameter text: Raw OCR text
    /// - Returns: Parsed transaction data
    func parse(_ text: String) -> ParsedTransaction {
        var result = ParsedTransaction()
        result.rawText = text

        // Detect payment source
        result.paymentSource = detectPaymentSource(text)

        // Extract amount
        result.amount = extractAmount(from: text)

        // Extract merchant
        result.merchant = extractMerchant(from: text)

        // Detect transaction type (default expense)
        result.type = detectTransactionType(text)

        // Calculate confidence
        result.confidence = calculateConfidence(result)

        return result
    }

    /// Detect payment platform from text
    private func detectPaymentSource(_ text: String) -> PaymentSource {
        let lowercased = text.lowercased()

        if lowercased.contains("微信") || lowercased.contains("wechat") {
            return .wechat
        } else if lowercased.contains("支付宝") || lowercased.contains("alipay") {
            return .alipay
        } else if lowercased.contains("银行") || lowercased.contains("bank") {
            return .bank
        }

        return .unknown
    }

    /// Extract amount using regex patterns
    private func extractAmount(from text: String) -> Decimal? {
        for pattern in amountPatterns {
            if let match = extractFirst(text, pattern: pattern) {
                // Remove whitespace and convert
                let cleaned = match.trimmingCharacters(in: .whitespaces)
                if let decimal = Decimal(string: cleaned) {
                    return decimal
                }
            }
        }
        return nil
    }

    /// Extract merchant name using regex patterns
    private func extractMerchant(from text: String) -> String? {
        for pattern in merchantPatterns {
            if let match = extractFirst(text, pattern: pattern) {
                let cleaned = match
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\n", with: "")
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }
        return nil
    }

    /// Detect if this is income or expense
    private func detectTransactionType(_ text: String) -> TransactionType {
        let incomeKeywords = ["收款", "转入", "到账", "收到", "红包"]
        for keyword in incomeKeywords {
            if text.contains(keyword) {
                return .income
            }
        }
        return .expense
    }

    /// Calculate parsing confidence score
    private func calculateConfidence(_ result: ParsedTransaction) -> Double {
        var score = 0.0

        if result.amount != nil { score += 0.5 }
        if result.merchant != nil { score += 0.3 }
        if result.paymentSource != .unknown { score += 0.2 }

        return score
    }

    /// Helper to extract first regex match
    private func extractFirst(_ text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        // Return first capture group if exists, otherwise full match
        let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range(at: 0)
        guard let swiftRange = Range(captureRange, in: text) else {
            return nil
        }

        return String(text[swiftRange])
    }
}
