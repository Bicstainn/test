//
//  BankSMSParserTests.swift
//  MoneyBuddyTests
//
//  Unit tests for BankSMSParser
//

import XCTest
@testable import MoneyBuddy

final class BankSMSParserTests: XCTestCase {

    var parser: BankSMSParser!

    override func setUp() {
        super.setUp()
        parser = BankSMSParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - ICBC Tests

    func testParseICBCSMS() {
        let sms = "【工商银行】您尾号1234的信用卡于01月15日支出(人民币)128.00元,在星巴克消费,当前可用额度5000.00元"

        let result = parser.parse(sms)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bankName, "工商银行")
        XCTAssertEqual(result?.amount, Decimal(128.00))
        XCTAssertEqual(result?.cardSuffix, "1234")
        XCTAssertTrue(result?.isExpense ?? false)
    }

    // MARK: - CCB Tests

    func testParseCCBSMS() {
        let sms = "【建设银行】您尾号5678的储蓄卡01月15日14:30支出人民币88.50(微信支付),余额1234.56元"

        let result = parser.parse(sms)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bankName, "建设银行")
        XCTAssertEqual(result?.amount, Decimal(88.50))
        XCTAssertEqual(result?.cardSuffix, "5678")
    }

    // MARK: - CMB Tests

    func testParseCMBSMS() {
        let sms = "【招商银行】您的尾号1111信用卡于01/15在美团外卖消费人民币35.80元"

        let result = parser.parse(sms)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bankName, "招商银行")
        XCTAssertEqual(result?.amount, Decimal(35.80))
    }

    // MARK: - ABC Tests

    func testParseABCSMS() {
        let sms = "【农业银行】您尾号9999的卡01月15日消费50.00元,在超市消费,余额500.00元"

        let result = parser.parse(sms)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bankName, "农业银行")
        XCTAssertEqual(result?.amount, Decimal(50.00))
    }

    // MARK: - BOC Tests

    func testParseBOCSMS() {
        let sms = "【中国银行】您2222卡01月15日支出200.00元,在京东商城消费"

        let result = parser.parse(sms)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bankName, "中国银行")
        XCTAssertEqual(result?.amount, Decimal(200.00))
    }

    // MARK: - Income Tests

    func testParseIncomeSMS() {
        let sms = "【工商银行】您尾号1234的储蓄卡01月15日收入(人民币)5000.00元,工资到账,当前余额10000.00元"

        let result = parser.parse(sms)

        XCTAssertNotNil(result)
        XCTAssertFalse(result?.isExpense ?? true)
    }

    func testParseTransferIncomeSMS() {
        let sms = "【招商银行】您的尾号1111卡01/15到账人民币100.00元,转账"

        let result = parser.parse(sms)

        XCTAssertNotNil(result)
        XCTAssertFalse(result?.isExpense ?? true)
    }

    // MARK: - Generic Pattern Tests

    func testParseGenericBankSMS() {
        let sms = "【某银行】您的卡消费68.00元"

        let result = parser.parse(sms)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amount, Decimal(68.00))
    }

    // MARK: - Edge Cases

    func testParseNonTransactionSMS() {
        let sms = "【工商银行】您的信用卡已成功还款,感谢使用工商银行"

        let result = parser.parse(sms)

        // Should return nil as there's no transaction amount
        XCTAssertNil(result)
    }

    func testParseEmptySMS() {
        let result = parser.parse("")

        XCTAssertNil(result)
    }

    func testParseVerificationCodeSMS() {
        let sms = "【工商银行】您的验证码是123456,请勿泄露"

        let result = parser.parse(sms)

        XCTAssertNil(result)
    }

    // MARK: - Bank Detection Tests

    func testDetectICBCBank() {
        let bank = BankSMS.detect(from: "工商银行")
        XCTAssertEqual(bank, .icbc)
    }

    func testDetectCMBBank() {
        let bank = BankSMS.detect(from: "招商银行")
        XCTAssertEqual(bank, .cmb)
    }

    func testDetectUnknownBank() {
        let bank = BankSMS.detect(from: "某某银行")
        XCTAssertNil(bank)
    }
}
