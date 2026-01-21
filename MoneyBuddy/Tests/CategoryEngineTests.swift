//
//  CategoryEngineTests.swift
//  MoneyBuddyTests
//
//  Unit tests for CategoryEngine
//

import XCTest
@testable import MoneyBuddy

final class CategoryEngineTests: XCTestCase {

    var engine: CategoryEngine!

    override func setUp() {
        super.setUp()
        engine = CategoryEngine.shared
        engine.clearCache()
    }

    override func tearDown() {
        engine.clearCache()
        engine = nil
        super.tearDown()
    }

    // MARK: - Food Category Tests

    func testClassifyFoodDelivery() {
        let result = engine.classifyLocal("美团外卖")

        XCTAssertEqual(result.category, .food)
        XCTAssertEqual(result.source, .keyword)
        XCTAssertGreaterThan(result.confidence, 0.5)
    }

    func testClassifyRestaurant() {
        let result = engine.classifyLocal("星巴克咖啡")

        XCTAssertEqual(result.category, .food)
    }

    func testClassifyFastFood() {
        let merchants = ["肯德基", "麦当劳", "必胜客", "德克士"]

        for merchant in merchants {
            let result = engine.classifyLocal(merchant)
            XCTAssertEqual(result.category, .food, "Failed for \(merchant)")
        }
    }

    // MARK: - Transport Category Tests

    func testClassifyRideShare() {
        let result = engine.classifyLocal("滴滴出行")

        XCTAssertEqual(result.category, .transport)
    }

    func testClassifyPublicTransport() {
        let merchants = ["地铁", "公交", "12306"]

        for merchant in merchants {
            let result = engine.classifyLocal(merchant)
            XCTAssertEqual(result.category, .transport, "Failed for \(merchant)")
        }
    }

    // MARK: - Shopping Category Tests

    func testClassifyOnlineShopping() {
        let merchants = ["淘宝", "京东", "拼多多", "天猫"]

        for merchant in merchants {
            let result = engine.classifyLocal(merchant)
            XCTAssertEqual(result.category, .shopping, "Failed for \(merchant)")
        }
    }

    // MARK: - Entertainment Category Tests

    func testClassifyEntertainment() {
        let merchants = ["爱奇艺", "B站", "网易云音乐"]

        for merchant in merchants {
            let result = engine.classifyLocal(merchant)
            XCTAssertEqual(result.category, .entertainment, "Failed for \(merchant)")
        }
    }

    // MARK: - Housing Category Tests

    func testClassifyHousing() {
        let merchants = ["房租", "物业", "水费", "电费"]

        for merchant in merchants {
            let result = engine.classifyLocal(merchant)
            XCTAssertEqual(result.category, .housing, "Failed for \(merchant)")
        }
    }

    // MARK: - Medical Category Tests

    func testClassifyMedical() {
        let merchants = ["医院", "药房", "体检中心"]

        for merchant in merchants {
            let result = engine.classifyLocal(merchant)
            XCTAssertEqual(result.category, .medical, "Failed for \(merchant)")
        }
    }

    // MARK: - Education Category Tests

    func testClassifyEducation() {
        let merchants = ["新东方", "学费", "得到"]

        for merchant in merchants {
            let result = engine.classifyLocal(merchant)
            XCTAssertEqual(result.category, .education, "Failed for \(merchant)")
        }
    }

    // MARK: - Income Category Tests

    func testClassifyIncome() {
        let merchants = ["工资", "奖金", "红包"]

        for merchant in merchants {
            let result = engine.classifyLocal(merchant)
            XCTAssertEqual(result.category, .income, "Failed for \(merchant)")
        }
    }

    // MARK: - Unknown Category Tests

    func testClassifyUnknownMerchant() {
        let result = engine.classifyLocal("某某公司")

        XCTAssertEqual(result.category, .other)
        XCTAssertEqual(result.source, .defaultValue)
    }

    // MARK: - Cache Tests

    func testCacheCorrection() {
        // Cache a correction
        engine.cacheCorrection(merchant: "测试商家", category: .food)

        // Verify it's cached
        let result = engine.classifyLocal("测试商家")

        XCTAssertEqual(result.category, .food)
        XCTAssertEqual(result.source, .cached)
    }

    func testCachePersistence() {
        // Cache a correction
        engine.cacheCorrection(merchant: "持久化测试", category: .entertainment)

        // Create new instance (simulates app restart)
        let newEngine = CategoryEngine.shared

        let result = newEngine.classifyLocal("持久化测试")

        XCTAssertEqual(result.category, .entertainment)
    }

    func testClearCache() {
        // Cache a correction
        engine.cacheCorrection(merchant: "清除测试", category: .shopping)

        // Clear cache
        engine.clearCache()

        // Verify it's cleared
        let result = engine.classifyLocal("清除测试")

        XCTAssertEqual(result.category, .other)
        XCTAssertEqual(result.source, .defaultValue)
    }

    // MARK: - Case Insensitivity Tests

    func testCaseInsensitiveMatching() {
        let result = engine.classifyLocal("STARBUCKS星巴克")

        XCTAssertEqual(result.category, .food)
    }

    // MARK: - Async AI Classification Tests

    func testAsyncClassificationWithoutAI() async {
        // Test with AI disabled
        let result = await engine.classify("某某商家", useAI: false)

        XCTAssertEqual(result.category, .other)
        XCTAssertEqual(result.source, .defaultValue)
    }
}
