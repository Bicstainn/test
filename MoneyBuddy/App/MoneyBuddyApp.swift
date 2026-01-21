//
//  MoneyBuddyApp.swift
//  MoneyBuddy
//
//  Main app entry point
//

import SwiftUI
import SwiftData

@main
struct MoneyBuddyApp: App {
    /// SwiftData model container
    let modelContainer: ModelContainer

    /// URL handler for receiving data from shortcuts
    @StateObject private var urlHandler = URLHandler.shared

    init() {
        // Initialize app configuration
        AppConfig.initialize()

        do {
            let schema = Schema([Transaction.self, Ledger.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(urlHandler)
                .onOpenURL { url in
                    urlHandler.handle(url)
                }
        }
        .modelContainer(modelContainer)
    }
}
