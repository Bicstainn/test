//
//  CharacterView.swift
//  MoneyBuddy
//
//  Mascot character with expression system (static placeholder for Live2D)
//

import SwiftUI

/// Character expression types
enum CharacterExpression: String, CaseIterable {
    case normal = "默认"
    case starryEyes = "星星眼"      // 收入大幅增加
    case bigStomach = "大胃袋"      // 餐饮支出大幅增加
    case tearyEyes = "眼含泪水"     // 医疗支出大幅增加
    case disgusted = "嫌弃脸"       // 月度支出远大于收入
    case happy = "开心"            // 记账成功
    case thinking = "思考"         // AI处理中

    /// Main emoji/symbol for expression
    var emoji: String {
        switch self {
        case .normal: return "😊"
        case .starryEyes: return "🤩"
        case .bigStomach: return "🍔"
        case .tearyEyes: return "🥺"
        case .disgusted: return "😒"
        case .happy: return "😄"
        case .thinking: return "🤔"
        }
    }

    /// SF Symbol for expression indicator
    var icon: String {
        switch self {
        case .normal: return "face.smiling"
        case .starryEyes: return "star.fill"
        case .bigStomach: return "fork.knife"
        case .tearyEyes: return "drop.fill"
        case .disgusted: return "hand.thumbsdown.fill"
        case .happy: return "heart.fill"
        case .thinking: return "brain.head.profile"
        }
    }

    /// Background color for expression
    var backgroundColor: Color {
        switch self {
        case .normal: return Color.blue.opacity(0.1)
        case .starryEyes: return Color.yellow.opacity(0.2)
        case .bigStomach: return Color.orange.opacity(0.2)
        case .tearyEyes: return Color.cyan.opacity(0.2)
        case .disgusted: return Color.purple.opacity(0.2)
        case .happy: return Color.green.opacity(0.2)
        case .thinking: return Color.gray.opacity(0.2)
        }
    }

    /// Expression description/dialogue
    var dialogue: String {
        switch self {
        case .normal: return "今天也要好好记账哦~"
        case .starryEyes: return "哇！收入增加了好多！继续加油！✨"
        case .bigStomach: return "吃货本色暴露了...要不要控制一下？🍜"
        case .tearyEyes: return "身体是革命的本钱，要多注意健康呀...💊"
        case .disgusted: return "这个月花太多了吧...钱包君在哭泣 💸"
        case .happy: return "记账成功！又是精打细算的一天！"
        case .thinking: return "让我想想..."
        }
    }
}

/// Expression trigger conditions
struct ExpressionTrigger {
    /// Threshold for "significant increase" (percentage)
    static let significantIncreaseThreshold: Double = 0.3  // 30%

    /// Threshold for expense > income ratio
    static let expenseOverIncomeThreshold: Double = 1.2  // 120%

    /// Evaluate expression based on financial data
    static func evaluate(
        currentMonthIncome: Decimal,
        lastMonthIncome: Decimal,
        currentMonthFoodExpense: Decimal,
        lastMonthFoodExpense: Decimal,
        currentMonthMedicalExpense: Decimal,
        lastMonthMedicalExpense: Decimal,
        currentMonthTotalExpense: Decimal
    ) -> CharacterExpression {
        // Priority 1: Monthly expense >> income (嫌弃脸)
        if currentMonthIncome > 0 {
            let expenseRatio = Double(truncating: (currentMonthTotalExpense / currentMonthIncome) as NSDecimalNumber)
            if expenseRatio > expenseOverIncomeThreshold {
                return .disgusted
            }
        } else if currentMonthTotalExpense > 0 {
            // No income but has expense
            return .disgusted
        }

        // Priority 2: Income significantly increased (星星眼)
        if lastMonthIncome > 0 {
            let incomeGrowth = Double(truncating: ((currentMonthIncome - lastMonthIncome) / lastMonthIncome) as NSDecimalNumber)
            if incomeGrowth > significantIncreaseThreshold {
                return .starryEyes
            }
        } else if currentMonthIncome > 0 {
            // Had no income last month, but has income this month
            return .starryEyes
        }

        // Priority 3: Medical expense significantly increased (眼含泪水)
        if lastMonthMedicalExpense > 0 {
            let medicalGrowth = Double(truncating: ((currentMonthMedicalExpense - lastMonthMedicalExpense) / lastMonthMedicalExpense) as NSDecimalNumber)
            if medicalGrowth > significantIncreaseThreshold {
                return .tearyEyes
            }
        } else if currentMonthMedicalExpense > 100 {
            // No medical expense last month but significant this month
            return .tearyEyes
        }

        // Priority 4: Food expense significantly increased (大胃袋)
        if lastMonthFoodExpense > 0 {
            let foodGrowth = Double(truncating: ((currentMonthFoodExpense - lastMonthFoodExpense) / lastMonthFoodExpense) as NSDecimalNumber)
            if foodGrowth > significantIncreaseThreshold {
                return .bigStomach
            }
        }

        // Default expression
        return .normal
    }
}

/// Character view with expression
struct CharacterView: View {
    @ObservedObject var store: TransactionStore
    @State private var currentExpression: CharacterExpression = .normal
    @State private var showDialogue = true
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            // Character face
            ZStack {
                // Background circle
                Circle()
                    .fill(currentExpression.backgroundColor)
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)

                // Expression emoji
                Text(currentExpression.emoji)
                    .font(.system(size: 56))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                // Expression indicator
                Image(systemName: currentExpression.icon)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(expressionIndicatorColor)
                    .clipShape(Circle())
                    .offset(x: 35, y: -35)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        isAnimating = false
                    }
                }
            }

            // Dialogue bubble
            if showDialogue {
                DialogueBubble(text: currentExpression.dialogue)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            updateExpression()
        }
        .onChange(of: store.allTransactions.count) { _, _ in
            updateExpression()
        }
    }

    private var expressionIndicatorColor: Color {
        switch currentExpression {
        case .starryEyes: return .yellow
        case .bigStomach: return .orange
        case .tearyEyes: return .cyan
        case .disgusted: return .purple
        case .happy: return .green
        case .thinking: return .gray
        case .normal: return .blue
        }
    }

    /// Update expression based on current financial data
    private func updateExpression() {
        let stats = calculateMonthlyStats()

        withAnimation(.easeInOut(duration: 0.3)) {
            currentExpression = ExpressionTrigger.evaluate(
                currentMonthIncome: stats.currentIncome,
                lastMonthIncome: stats.lastIncome,
                currentMonthFoodExpense: stats.currentFood,
                lastMonthFoodExpense: stats.lastFood,
                currentMonthMedicalExpense: stats.currentMedical,
                lastMonthMedicalExpense: stats.lastMedical,
                currentMonthTotalExpense: stats.currentExpense
            )
        }
    }

    /// Calculate monthly statistics for expression evaluation
    private func calculateMonthlyStats() -> MonthlyStats {
        let calendar = Calendar.current
        let now = Date()

        // Current month range
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let currentMonthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!

        // Last month range
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart)!
        let lastMonthEnd = currentMonthStart

        // Filter transactions
        let currentMonthTx = store.allTransactions.filter { $0.date >= currentMonthStart && $0.date < currentMonthEnd }
        let lastMonthTx = store.allTransactions.filter { $0.date >= lastMonthStart && $0.date < lastMonthEnd }

        return MonthlyStats(
            currentIncome: sumAmount(currentMonthTx.filter { $0.type == .income }),
            lastIncome: sumAmount(lastMonthTx.filter { $0.type == .income }),
            currentExpense: sumAmount(currentMonthTx.filter { $0.type == .expense }),
            lastExpense: sumAmount(lastMonthTx.filter { $0.type == .expense }),
            currentFood: sumAmount(currentMonthTx.filter { $0.type == .expense && $0.category == .food }),
            lastFood: sumAmount(lastMonthTx.filter { $0.type == .expense && $0.category == .food }),
            currentMedical: sumAmount(currentMonthTx.filter { $0.type == .expense && $0.category == .medical }),
            lastMedical: sumAmount(lastMonthTx.filter { $0.type == .expense && $0.category == .medical })
        )
    }

    private func sumAmount(_ transactions: [Transaction]) -> Decimal {
        transactions.reduce(Decimal.zero) { $0 + $1.amount }
    }
}

/// Monthly statistics for expression calculation
struct MonthlyStats {
    let currentIncome: Decimal
    let lastIncome: Decimal
    let currentExpense: Decimal
    let lastExpense: Decimal
    let currentFood: Decimal
    let lastFood: Decimal
    let currentMedical: Decimal
    let lastMedical: Decimal
}

/// Dialogue bubble view
struct DialogueBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                Triangle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 12, height: 8)
                    .offset(y: -4),
                alignment: .top
            )
    }
}

/// Triangle shape for dialogue bubble
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Compact character view for embedding in other views
struct CompactCharacterView: View {
    let expression: CharacterExpression

    var body: some View {
        HStack(spacing: 8) {
            Text(expression.emoji)
                .font(.title2)

            Text(expression.dialogue)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(expression.backgroundColor)
        .cornerRadius(20)
    }
}

// MARK: - Preview

#Preview("Character View") {
    CharacterView(store: TransactionStore(modelContext: try! ModelContainer(for: Transaction.self).mainContext))
        .padding()
}

#Preview("All Expressions") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(CharacterExpression.allCases, id: \.self) { expression in
                HStack {
                    Text(expression.emoji)
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text(expression.rawValue)
                            .font(.headline)
                        Text(expression.dialogue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(expression.backgroundColor)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}
