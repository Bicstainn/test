//
//  SettingsView.swift
//  MoneyBuddy
//
//  App settings and configuration
//

import SwiftUI

/// Settings view
struct SettingsView: View {
    /// DeepSeek API key
    @State private var apiKey: String = DeepSeekConfig.apiKey

    /// Show API key
    @State private var showAPIKey: Bool = false

    /// Show shortcut guide
    @State private var showShortcutGuide: Bool = false

    /// Show about
    @State private var showAbout: Bool = false

    /// Show clear data confirmation
    @State private var showClearConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Quick setup
                Section {
                    Button {
                        showShortcutGuide = true
                    } label: {
                        Label("设置快捷指令", systemImage: "wand.and.stars")
                    }
                } header: {
                    Text("快速设置")
                } footer: {
                    Text("配置轻敲背面OCR和银行短信自动记账")
                }

                // AI Settings
                Section {
                    HStack {
                        if showAPIKey {
                            TextField("API Key", text: $apiKey)
                                .textContentType(.password)
                        } else {
                            SecureField("API Key", text: $apiKey)
                        }

                        Button {
                            showAPIKey.toggle()
                        } label: {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        }
                    }

                    Button("保存") {
                        DeepSeekConfig.apiKey = apiKey
                    }
                    .disabled(apiKey == DeepSeekConfig.apiKey)
                } header: {
                    Text("DeepSeek AI")
                } footer: {
                    Text("用于智能分类和周报分析。获取API Key: api.deepseek.com")
                }

                // Data management
                Section {
                    Button {
                        CategoryEngine.shared.clearCache()
                    } label: {
                        Label("清除分类缓存", systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("清除所有数据", systemImage: "trash")
                    }
                } header: {
                    Text("数据管理")
                }

                // About
                Section {
                    Button {
                        showAbout = true
                    } label: {
                        Label("关于 MoneyBuddy", systemImage: "info.circle")
                    }

                    Link(destination: URL(string: "https://api-docs.deepseek.com/")!) {
                        Label("DeepSeek API文档", systemImage: "link")
                    }
                } header: {
                    Text("关于")
                }

                // Version info
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("开发者")
                        Spacer()
                        Text("MoneyBuddy Team")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showShortcutGuide) {
                ShortcutGuideView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .alert("确认清除", isPresented: $showClearConfirmation) {
                Button("清除", role: .destructive) {
                    // Clear data action would be handled by TransactionStore
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要清除所有交易记录吗？此操作无法撤销。")
            }
        }
    }
}

/// About view
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("MoneyBuddy")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("智能记账助手")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Divider()

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "camera.viewfinder", title: "轻敲背面OCR", description: "敲两下手机背面，自动截屏识别支付信息")
                        FeatureRow(icon: "message.fill", title: "银行短信解析", description: "自动解析银行消费短信，免手动输入")
                        FeatureRow(icon: "sparkles", title: "AI智能分类", description: "DeepSeek AI自动识别消费类别")
                        FeatureRow(icon: "chart.pie.fill", title: "消费分析", description: "可视化统计和AI周报分析")
                    }
                    .padding()

                    Divider()

                    // Privacy
                    VStack(spacing: 8) {
                        Text("隐私说明")
                            .font(.headline)
                        Text("所有数据存储在本地设备，仅在使用AI功能时发送商家名称到DeepSeek API进行分类。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Feature row for about view
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}
