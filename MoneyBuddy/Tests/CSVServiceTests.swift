//
//  CSVServiceTests.swift
//  MoneyBuddyTests
//
//  Unit tests for CSVService
//

import XCTest
@testable import MoneyBuddy

final class CSVServiceTests: XCTestCase {

    var service: CSVService!

    override func setUp() {
        super.setUp()
        service = CSVService.shared
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Export Tests

    func testExportSingleTransaction() {
        let transactions = [
            createTransaction(amount: 35.50, category: .food, merchant: "星巴克")
        ]

        let csv = service.exportToCSV(transactions)

        XCTAssertTrue(csv.contains("日期"))
        XCTAssertTrue(csv.contains("金额"))
        XCTAssertTrue(csv.contains("35.5"))
        XCTAssertTrue(csv.contains("星巴克"))
        XCTAssertTrue(csv.contains("餐饮"))
    }

    func testExportMultipleTransactions() {
        let transactions = [
            createTransaction(amount: 35.50, category: .food, merchant: "星巴克"),
            createTransaction(amount: 18.00, category: .transport, merchant: "滴滴出行"),
            createTransaction(amount: 99.00, category: .shopping, merchant: "淘宝")
        ]

        let csv = service.exportToCSV(transactions)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Header + 3 data rows
        XCTAssertEqual(lines.count, 4)
    }

    func testExportEmptyTransactions() {
        let transactions: [Transaction] = []

        let csv = service.exportToCSV(transactions)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Only header
        XCTAssertEqual(lines.count, 1)
    }

    func testExportWithSpecialCharacters() {
        let transactions = [
            createTransaction(amount: 50.00, category: .food, merchant: "餐厅, 美食")
        ]

        let csv = service.exportToCSV(transactions)

        // Should be properly escaped
        XCTAssertTrue(csv.contains("\"餐厅, 美食\""))
    }

    // MARK: - Import Tests

    func testImportValidCSV() throws {
        let csv = """
        金额,类型,分类,商家,备注
        35.50,支出,餐饮,星巴克,咖啡
        18.00,支出,交通,滴滴,打车
        """

        let results = try service.importFromCSV(csv)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].amount, Decimal(35.50))
        XCTAssertEqual(results[0].merchant, "星巴克")
        XCTAssertEqual(results[1].amount, Decimal(18.00))
    }

    func testImportWithDate() throws {
        let csv = """
        日期,金额,类型,分类,商家
        2024-01-15,50.00,支出,餐饮,美团外卖
        """

        let results = try service.importFromCSV(csv)

        XCTAssertEqual(results.count, 1)
        XCTAssertNotNil(results[0].date)
    }

    func testImportIncomeType() throws {
        let csv = """
        金额,类型,分类,商家
        5000.00,收入,收入,工资
        """

        let results = try service.importFromCSV(csv)

        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].isExpense)
    }

    func testImportMissingRequiredColumn() {
        let csv = """
        分类,商家
        餐饮,星巴克
        """

        XCTAssertThrowsError(try service.importFromCSV(csv)) { error in
            guard case CSVError.missingRequiredColumn = error else {
                XCTFail("Expected missingRequiredColumn error")
                return
            }
        }
    }

    func testImportInvalidAmountFormat() {
        let csv = """
        金额,类型
        invalid,支出
        """

        XCTAssertThrowsError(try service.importFromCSV(csv)) { error in
            guard case CSVError.parseError = error else {
                XCTFail("Expected parseError")
                return
            }
        }
    }

    func testImportEmptyCSV() {
        let csv = ""

        XCTAssertThrowsError(try service.importFromCSV(csv)) { error in
            guard case CSVError.invalidFormat = error else {
                XCTFail("Expected invalidFormat error")
                return
            }
        }
    }

    func testImportOnlyHeader() {
        let csv = "金额,类型,分类"

        XCTAssertThrowsError(try service.importFromCSV(csv)) { error in
            guard case CSVError.invalidFormat = error else {
                XCTFail("Expected invalidFormat error")
                return
            }
        }
    }

    func testImportWithQuotedFields() throws {
        let csv = """
        金额,类型,商家,备注
        50.00,支出,"星巴克,咖啡店","午后咖啡"
        """

        let results = try service.importFromCSV(csv)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].merchant, "星巴克,咖啡店")
    }

    // MARK: - Round-Trip Tests

    func testExportImportRoundTrip() throws {
        let originalTransactions = [
            createTransaction(amount: 35.50, category: .food, merchant: "星巴克"),
            createTransaction(amount: 18.00, category: .transport, merchant: "滴滴出行")
        ]

        // Export
        let csv = service.exportToCSV(originalTransactions)

        // Import
        let imported = try service.importFromCSV(csv)

        XCTAssertEqual(imported.count, originalTransactions.count)
        XCTAssertEqual(imported[0].amount, originalTransactions[0].amount)
        XCTAssertEqual(imported[0].merchant, originalTransactions[0].merchant)
    }

    // MARK: - Helper Methods

    private func createTransaction(
        amount: Decimal,
        type: TransactionType = .expense,
        category: Category,
        merchant: String?
    ) -> Transaction {
        Transaction(
            amount: amount,
            type: type,
            category: category,
            merchant: merchant,
            date: Date(),
            source: .manual
        )
    }
}
