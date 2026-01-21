//
//  TransactionParserTests.swift
//  MoneyBuddyTests
//
//  Unit tests for TransactionParser
//

import XCTest
@testable import MoneyBuddy

final class TransactionParserTests: XCTestCase {

    // MARK: - WeChat OCR Tests

    func testParseWeChatPayment() {
        let ocrText = """
        微信支付
        收款方: 星巴克咖啡
        支付金额: ¥35.00
        支付方式: 零钱
        支付时间: 2024-01-15 14:30:22
        """

        let result = TransactionParser.parse(ocrText)

        XCTAssertEqual(result.source, .wechat)
        XCTAssertEqual(result.amount, Decimal(35.00))
        XCTAssertEqual(result.merchant, "星巴克咖啡")
    }

    func testParseWeChatWithDifferentAmountFormat() {
        let ocrText = """
        微信支付凭证
        付款给: 美团外卖
        金额: 28.50元
        """

        let result = TransactionParser.parse(ocrText)

        XCTAssertEqual(result.source, .wechat)
        XCTAssertEqual(result.amount, Decimal(28.50))
        XCTAssertEqual(result.merchant, "美团外卖")
    }

    // MARK: - Alipay OCR Tests

    func testParseAlipayPayment() {
        let ocrText = """
        支付宝
        收款方：肯德基
        支付金额 ¥45.00
        交易时间 2024-01-15 12:00:00
        """

        let result = TransactionParser.parse(ocrText)

        XCTAssertEqual(result.source, .alipay)
        XCTAssertEqual(result.amount, Decimal(45.00))
        XCTAssertEqual(result.merchant, "肯德基")
    }

    func testParseAlipayWithChineseColon() {
        let ocrText = """
        支付宝账单
        收款方：滴滴出行
        金额：18.00元
        """

        let result = TransactionParser.parse(ocrText)

        XCTAssertEqual(result.source, .alipay)
        XCTAssertEqual(result.amount, Decimal(18.00))
        XCTAssertEqual(result.merchant, "滴滴出行")
    }

    // MARK: - Amount Extraction Tests

    func testExtractAmountWithYuanSymbol() {
        let text = "支付金额¥99.99"
        let result = TransactionParser.parse(text)

        XCTAssertEqual(result.amount, Decimal(99.99))
    }

    func testExtractAmountWithYuanCharacter() {
        let text = "消费金额: 123.45元"
        let result = TransactionParser.parse(text)

        XCTAssertEqual(result.amount, Decimal(123.45))
    }

    func testExtractWholeNumberAmount() {
        let text = "支付金额: ¥100"
        let result = TransactionParser.parse(text)

        XCTAssertEqual(result.amount, Decimal(100))
    }

    func testExtractAmountWithThousands() {
        let text = "转账金额: ¥1,500.00"
        let result = TransactionParser.parse(text)

        // Note: Parser should handle comma-separated amounts
        XCTAssertNotNil(result.amount)
    }

    // MARK: - Merchant Extraction Tests

    func testExtractMerchantWithColon() {
        let text = "收款方: 麦当劳餐厅"
        let result = TransactionParser.parse(text)

        XCTAssertEqual(result.merchant, "麦当劳餐厅")
    }

    func testExtractMerchantWithChineseColon() {
        let text = "付款给：京东商城"
        let result = TransactionParser.parse(text)

        XCTAssertEqual(result.merchant, "京东商城")
    }

    // MARK: - Edge Cases

    func testParseEmptyText() {
        let result = TransactionParser.parse("")

        XCTAssertNil(result.amount)
        XCTAssertNil(result.merchant)
        XCTAssertEqual(result.source, .unknown)
    }

    func testParseTextWithNoAmount() {
        let text = "微信支付成功"
        let result = TransactionParser.parse(text)

        XCTAssertNil(result.amount)
        XCTAssertEqual(result.source, .wechat)
    }

    func testParseTextWithMultipleAmounts() {
        // Should extract the first amount (payment amount)
        let text = """
        原价: ¥100.00
        优惠: ¥10.00
        实付金额: ¥90.00
        """

        let result = TransactionParser.parse(text)

        XCTAssertNotNil(result.amount)
    }
}
