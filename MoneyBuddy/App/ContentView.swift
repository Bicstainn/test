//
//  ContentView.swift
//  MoneyBuddy
//
//  Main tab view container
//

import SwiftUI
import SwiftData

/// Main content view with tab navigation
struct ContentView: View {
    /// Environment model context
    @Environment(\.modelContext) private var modelContext

    /// URL handler for incoming data
    @EnvironmentObject private var urlHandler: URLHandler

    /// Selected tab index
    @State private var selectedTab: Int = 0

    /// Transaction store
    @State private var store: TransactionStore?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard tab
            if let store = store {
                DashboardView(store: store)
                    .tabItem {
                        Label("账单", systemImage: "list.bullet.rectangle")
                    }
                    .tag(0)
            }

            // Analytics tab
            if let store = store {
                AnalyticsView(store: store)
                    .tabItem {
                        Label("统计", systemImage: "chart.pie")
                    }
                    .tag(1)
            }

            // Manual record tab
            if let store = store {
                ManualRecordView(store: store)
                    .tabItem {
                        Label("记账", systemImage: "plus.circle.fill")
                    }
                    .tag(2)
            }

            // Settings tab
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(3)
        }
        .sheet(isPresented: $urlHandler.showQuickRecord) {
            if let parsed = urlHandler.parsedTransaction, let store = store {
                QuickRecordSheet(
                    parsed: parsed,
                    store: store,
                    onDismiss: {
                        urlHandler.clearPendingAction()
                    }
                )
            }
        }
        .onAppear {
            if store == nil {
                store = TransactionStore(modelContext: modelContext)
            }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(URLHandler.shared)
        .modelContainer(for: Transaction.self, inMemory: true)
}
