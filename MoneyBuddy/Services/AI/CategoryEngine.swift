//
//  CategoryEngine.swift
//  MoneyBuddy
//
//  Local keyword matching + AI fallback classification engine
//

import Foundation

/// Classification result with source
struct ClassificationResult {
    let category: Category
    let source: ClassificationSource
    let confidence: Double
}

/// Source of classification
enum ClassificationSource {
    case keyword      // Matched local keyword
    case cached       // From user correction cache
    case ai           // DeepSeek AI classification
    case defaultValue // Default fallback
}

/// Category classification engine
/// Uses local keywords first, then AI as fallback
final class CategoryEngine {
    /// Shared instance
    static let shared = CategoryEngine()

    /// Keyword to category mapping
    private let keywords: [Category: [String]] = [
        .food: [
            "美团", "饿了么", "肯德基", "麦当劳", "星巴克", "餐厅", "餐饮",
            "外卖", "咖啡", "奶茶", "火锅", "烧烤", "面馆", "饭店", "食堂",
            "瑞幸", "喜茶", "海底捞", "必胜客", "德克士", "汉堡王", "subway",
            "超市", "便利店", "全家", "711", "罗森", "盒马", "叮咚", "每日优鲜"
        ],
        .transport: [
            "滴滴", "高德", "地铁", "公交", "加油", "停车", "出租",
            "打车", "顺风车", "花小猪", "曹操", "T3", "首汽", "神州",
            "铁路", "12306", "航空", "机票", "火车票", "汽车票", "船票",
            "ofo", "摩拜", "哈啰", "青桔", "共享单车", "ETC"
        ],
        .shopping: [
            "淘宝", "京东", "拼多多", "天猫", "唯品会", "苏宁", "国美",
            "购物", "商城", "百货", "超市", "便利店", "小米", "华为",
            "Apple", "ZARA", "HM", "优衣库", "UNIQLO", "Nike", "Adidas",
            "服装", "鞋", "包", "化妆品", "护肤", "数码", "电器"
        ],
        .entertainment: [
            "电影", "游戏", "视频", "音乐", "KTV", "网吧", "棋牌",
            "爱奇艺", "优酷", "腾讯视频", "B站", "bilibili", "网易云", "QQ音乐",
            "Steam", "App Store", "王者荣耀", "抖音", "快手",
            "演唱会", "展览", "门票", "景区", "旅游", "酒店", "民宿"
        ],
        .housing: [
            "房租", "物业", "水费", "电费", "燃气", "暖气", "宽带",
            "装修", "家具", "家电", "维修", "保洁", "搬家",
            "贝壳", "链家", "自如", "蛋壳"
        ],
        .medical: [
            "医院", "药房", "药店", "诊所", "体检", "挂号",
            "医疗", "看病", "手术", "住院", "门诊", "急诊",
            "医保", "社保", "保险"
        ],
        .education: [
            "学费", "书店", "培训", "课程", "教育", "学习",
            "新东方", "学而思", "得到", "知乎", "喜马拉雅",
            "考试", "报名", "证书", "留学"
        ],
        .income: [
            "工资", "奖金", "红包", "转账收入", "退款", "理财收益",
            "兼职", "报销", "补贴", "收款"
        ]
    ]

    /// User correction cache (merchant -> category)
    private var correctionCache: [String: Category] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "category_corrections"),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return dict.compactMapValues { Category(rawValue: $0) }
        }
        set {
            let dict = newValue.mapValues { $0.rawValue }
            if let data = try? JSONEncoder().encode(dict) {
                UserDefaults.standard.set(data, forKey: "category_corrections")
            }
        }
    }

    private init() {}

    /// Classify merchant with local keywords + AI fallback
    /// - Parameters:
    ///   - merchant: Merchant name
    ///   - useAI: Whether to use AI as fallback (default true)
    /// - Returns: Classification result
    func classify(_ merchant: String, useAI: Bool = true) async -> ClassificationResult {
        // Step 1: Check user correction cache
        if let cached = correctionCache[merchant] {
            return ClassificationResult(category: cached, source: .cached, confidence: 1.0)
        }

        // Step 2: Try local keyword matching
        if let (category, confidence) = matchKeyword(merchant) {
            return ClassificationResult(category: category, source: .keyword, confidence: confidence)
        }

        // Step 3: Try AI classification if enabled
        if useAI {
            do {
                let category = try await DeepSeekService.shared.classify(merchant)
                // Cache the AI result for future use
                cacheCorrection(merchant: merchant, category: category)
                return ClassificationResult(category: category, source: .ai, confidence: 0.8)
            } catch {
                // AI failed, fall through to default
            }
        }

        // Step 4: Default fallback
        return ClassificationResult(category: .other, source: .defaultValue, confidence: 0.0)
    }

    /// Quick synchronous classification using only local keywords
    func classifyLocal(_ merchant: String) -> ClassificationResult {
        // Check cache first
        if let cached = correctionCache[merchant] {
            return ClassificationResult(category: cached, source: .cached, confidence: 1.0)
        }

        // Try keyword matching
        if let (category, confidence) = matchKeyword(merchant) {
            return ClassificationResult(category: category, source: .keyword, confidence: confidence)
        }

        return ClassificationResult(category: .other, source: .defaultValue, confidence: 0.0)
    }

    /// Cache user correction
    /// - Parameters:
    ///   - merchant: Merchant name
    ///   - category: Correct category
    func cacheCorrection(merchant: String, category: Category) {
        var cache = correctionCache
        cache[merchant] = category
        correctionCache = cache
    }

    /// Match merchant against keywords
    private func matchKeyword(_ merchant: String) -> (Category, Double)? {
        let lowercased = merchant.lowercased()

        for (category, categoryKeywords) in keywords {
            for keyword in categoryKeywords {
                if lowercased.contains(keyword.lowercased()) {
                    // Calculate confidence based on match quality
                    let confidence = keyword.count >= 3 ? 0.9 : 0.7
                    return (category, confidence)
                }
            }
        }

        return nil
    }

    /// Clear all cached corrections
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "category_corrections")
    }
}
