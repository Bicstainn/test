//
//  ChatView.swift
//  MoneyBuddy
//
//  AI chat interface for answering questions about transactions
//

import SwiftUI
import SwiftData

/// Chat message model
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(content: String, isUser: Bool) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

/// AI Chat view
struct ChatView: View {
    /// Transaction store for context
    @ObservedObject var store: TransactionStore

    /// Chat messages
    @State private var messages: [ChatMessage] = []

    /// Current input
    @State private var inputText: String = ""

    /// Loading state
    @State private var isLoading: Bool = false

    /// Scroll proxy for auto-scroll
    @Namespace private var bottomID

    @Environment(\.dismiss) private var dismiss

    /// Quick question suggestions
    private let suggestions = [
        "这周花了多少钱？",
        "哪个类别花费最多？",
        "最近有什么大额消费？",
        "给我一些省钱建议"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            if messages.isEmpty {
                                welcomeSection
                            }

                            // Messages
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                            }

                            // Loading indicator
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .padding(.horizontal)
                                    Text("正在思考...")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.leading)
                            }

                            // Scroll anchor
                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(bottomID)
                        }
                    }
                }

                Divider()

                // Input area
                inputArea
            }
            .navigationTitle("AI助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        messages.removeAll()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(messages.isEmpty)
                }
            }
        }
    }

    /// Welcome section with suggestions
    private var welcomeSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("MoneyBuddy AI助手")
                .font(.title2)
                .fontWeight(.bold)

            Text("我可以帮你分析消费记录、回答账单问题")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Quick suggestions
            VStack(spacing: 8) {
                Text("试试问我：")
                    .font(.caption)
                    .foregroundColor(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            sendMessage(suggestion)
                        } label: {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                        }
                    }
                }
            }
            .padding(.top)
        }
        .padding(.vertical, 40)
    }

    /// Input area
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("输入问题...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)

            Button {
                sendMessage(inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.isEmpty ? .gray : .blue)
            }
            .disabled(inputText.isEmpty || isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    /// Send a message
    private func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        Task {
            do {
                let response = try await DeepSeekService.shared.answerQuestion(
                    text,
                    context: store.recentTransactions(limit: 50)
                )
                let aiMessage = ChatMessage(content: response, isUser: false)

                await MainActor.run {
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                let errorMessage = ChatMessage(
                    content: "抱歉，我遇到了一些问题：\(error.localizedDescription)",
                    isUser: false
                )
                await MainActor.run {
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
}

/// Message bubble view
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isUser ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(18)

                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !message.isUser {
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

/// Flow layout for suggestion buttons
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    struct FlowResult {
        var sizes: [CGSize] = []
        var positions: [CGPoint] = []
        var size: CGSize = .zero

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            var rowMaxHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                sizes.append(size)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowMaxHeight + spacing
                    rowMaxHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowMaxHeight = max(rowMaxHeight, size.height)
                x += size.width + spacing
                maxHeight = max(maxHeight, y + size.height)
            }

            size = CGSize(width: width, height: maxHeight)
        }
    }
}

#Preview {
    ChatView(store: TransactionStore(modelContext: try! ModelContainer(for: Transaction.self).mainContext))
}
