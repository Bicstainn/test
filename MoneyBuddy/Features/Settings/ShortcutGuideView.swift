//
//  ShortcutGuideView.swift
//  MoneyBuddy
//
//  iOS Shortcuts setup guide
//

import SwiftUI

/// Shortcut setup guide view
struct ShortcutGuideView: View {
    @Environment(\.dismiss) private var dismiss

    /// Current step
    @State private var currentStep: Int = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $currentStep) {
                // Step 1: OCR Shortcut
                ocrShortcutStep
                    .tag(0)

                // Step 2: SMS Shortcut
                smsShortcutStep
                    .tag(1)

                // Step 3: Back Tap Setup
                backTapStep
                    .tag(2)

                // Step 4: Complete
                completeStep
                    .tag(3)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle("快捷指令设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    /// OCR shortcut setup step
    private var ocrShortcutStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                stepHeader(
                    icon: "camera.viewfinder",
                    title: "设置OCR记账快捷指令",
                    subtitle: "步骤 1/4"
                )

                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    instructionRow(number: 1, text: "打开「快捷指令」App")
                    instructionRow(number: 2, text: "点击右上角「+」创建新快捷指令")
                    instructionRow(number: 3, text: "添加以下操作：")

                    // Code block
                    codeBlock("""
                    1. 截屏
                    2. 从截图提取文字
                    3. 拷贝到剪贴板
                    4. 打开URL: moneybuddy://ocr-record
                    """)

                    instructionRow(number: 4, text: "将快捷指令命名为「MoneyBuddy记账」")
                }
                .padding()

                Spacer()
            }
            .padding()
        }
    }

    /// SMS shortcut setup step
    private var smsShortcutStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                stepHeader(
                    icon: "message.fill",
                    title: "设置银行短信自动化",
                    subtitle: "步骤 2/4"
                )

                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    instructionRow(number: 1, text: "在快捷指令App中，切换到「自动化」标签")
                    instructionRow(number: 2, text: "点击「+」→ 「创建个人自动化」")
                    instructionRow(number: 3, text: "选择「信息」作为触发条件")
                    instructionRow(number: 4, text: "设置发送者为银行号码：")

                    // Bank numbers
                    codeBlock("""
                    95588 (工商银行)
                    95533 (建设银行)
                    95599 (农业银行)
                    95566 (中国银行)
                    95555 (招商银行)
                    """)

                    instructionRow(number: 5, text: "添加操作：")

                    codeBlock("""
                    1. 获取快捷指令输入
                    2. 匹配文字: 支出|消费|扣款
                    3. 如果匹配:
                       - URL编码内容
                       - 打开URL: moneybuddy://sms-record?raw={内容}
                    """)

                    instructionRow(number: 6, text: "关闭「运行前询问」(iOS 17+)")
                }
                .padding()

                Spacer()
            }
            .padding()
        }
    }

    /// Back tap setup step
    private var backTapStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                stepHeader(
                    icon: "hand.tap.fill",
                    title: "设置轻敲背面",
                    subtitle: "步骤 3/4"
                )

                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    instructionRow(number: 1, text: "打开「设置」App")
                    instructionRow(number: 2, text: "进入「辅助功能」→「触控」")
                    instructionRow(number: 3, text: "滑动到底部，点击「轻点背面」")
                    instructionRow(number: 4, text: "选择「轻点两下」")
                    instructionRow(number: 5, text: "滑动到最底部，找到「快捷指令」分组")
                    instructionRow(number: 6, text: "选择「MoneyBuddy记账」")

                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Label("提示", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("• 轻敲背面功能需要 iPhone 8 或更新机型")
                        Text("• 建议使用「轻点两下」避免误触")
                        Text("• 戴壳可能影响识别，可能需要稍用力")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()

                Spacer()
            }
            .padding()
        }
    }

    /// Complete step
    private var completeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("设置完成!")
                .font(.title)
                .fontWeight(.bold)

            Text("现在您可以：")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                usageRow(icon: "hand.tap.fill", text: "敲两下手机背面快速记账")
                usageRow(icon: "message.fill", text: "收到银行短信自动记录")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Button {
                dismiss()
            } label: {
                Text("开始使用")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    /// Step header view
    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    /// Instruction row
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.body)
        }
    }

    /// Code block
    private func codeBlock(_ code: String) -> some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
    }

    /// Usage row
    private func usageRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
        }
    }
}

#Preview {
    ShortcutGuideView()
}
