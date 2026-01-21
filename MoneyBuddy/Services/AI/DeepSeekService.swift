//
//  DeepSeekService.swift
//  MoneyBuddy
//
//  DeepSeek API integration for AI classification and analysis
//

import Foundation

/// DeepSeek API configuration
enum DeepSeekConfig {
    static let baseURL = "https://api.deepseek.com/chat/completions"
    static let chatModel = "deepseek-chat"
    static let reasonerModel = "deepseek-reasoner"

    /// API key stored in UserDefaults (should be set by user in settings)
    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: "deepseek_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "deepseek_api_key") }
    }
}

/// DeepSeek API request structure
struct DeepSeekRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int

    struct Message: Encodable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

/// DeepSeek API response structure
struct DeepSeekResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }

    var content: String? {
        choices.first?.message.content
    }
}

/// DeepSeek service errors
enum DeepSeekError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "请先在设置中配置DeepSeek API密钥"
        case .invalidURL:
            return "无效的API地址"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError(let error):
            return "解析错误: \(error.localizedDescription)"
        case .emptyResponse:
            return "AI返回了空响应"
        }
    }
}

/// DeepSeek API service
final class DeepSeekService {
    /// Shared instance
    static let shared = DeepSeekService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    /// Classify merchant into category
    /// - Parameter merchant: Merchant name
    /// - Returns: Category classification
    func classify(_ merchant: String) async throws -> Category {
        let prompt = """
        请将以下交易商家分类到对应类别。

        可选类别：餐饮、交通、购物、娱乐、住房、医疗、教育、收入、其他

        商家名称：\(merchant)

        请只回复类别名称，不要包含任何其他内容。
        """

        let response = try await chat(prompt: prompt, model: DeepSeekConfig.chatModel)
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)

        return Category(rawValue: trimmed) ?? .other
    }

    /// Generate weekly spending report
    /// - Parameter transactions: List of transactions
    /// - Returns: AI generated report
    func generateWeeklyReport(_ transactions: [Transaction]) async throws -> String {
        let summary = formatTransactionsForPrompt(transactions)

        let prompt = """
        分析以下一周消费记录，生成简短报告。

        消费记录：
        \(summary)

        请提供：
        1. 消费概况（总支出、笔数）
        2. 分类占比分析
        3. 消费趋势观察
        4. 一条实用省钱建议

        要求：轻松友好的语气，200字以内。
        """

        return try await chat(prompt: prompt, model: DeepSeekConfig.reasonerModel)
    }

    /// Answer user question about transactions
    /// - Parameters:
    ///   - question: User's question
    ///   - transactions: Context transactions
    /// - Returns: AI response
    func answerQuestion(_ question: String, context transactions: [Transaction]) async throws -> String {
        let summary = formatTransactionsForPrompt(transactions)

        let prompt = """
        你是MoneyBuddy记账助手。根据用户的消费记录回答问题。

        最近消费记录：
        \(summary)

        用户问题：\(question)

        请简洁准确地回答，100字以内。
        """

        return try await chat(prompt: prompt, model: DeepSeekConfig.chatModel)
    }

    /// Send chat request to DeepSeek API
    private func chat(prompt: String, model: String, temperature: Double = 0.7) async throws -> String {
        guard !DeepSeekConfig.apiKey.isEmpty else {
            throw DeepSeekError.noAPIKey
        }

        guard let url = URL(string: DeepSeekConfig.baseURL) else {
            throw DeepSeekError.invalidURL
        }

        let request = DeepSeekRequest(
            model: model,
            messages: [.init(role: "user", content: prompt)],
            temperature: temperature,
            maxTokens: 500
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(DeepSeekConfig.apiKey)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw DeepSeekError.decodingError(error)
        }

        let data: Data
        do {
            (data, _) = try await session.data(for: urlRequest)
        } catch {
            throw DeepSeekError.networkError(error)
        }

        let response: DeepSeekResponse
        do {
            response = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
        } catch {
            throw DeepSeekError.decodingError(error)
        }

        guard let content = response.content, !content.isEmpty else {
            throw DeepSeekError.emptyResponse
        }

        return content
    }

    /// Format transactions for prompt
    private func formatTransactionsForPrompt(_ transactions: [Transaction]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"

        return transactions.prefix(50).map { tx in
            let date = formatter.string(from: tx.date)
            let sign = tx.type == .expense ? "-" : "+"
            let merchant = tx.merchant ?? tx.category.rawValue
            return "\(date) \(merchant) \(sign)¥\(tx.amount)"
        }.joined(separator: "\n")
    }
}
