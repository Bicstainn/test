//
//  Ledger.swift
//  MoneyBuddy
//
//  Multi-ledger support model
//

import Foundation
import SwiftData

/// Ledger model for multi-account support
@Model
final class Ledger {
    /// Unique identifier
    var id: UUID

    /// Ledger name
    var name: String

    /// Ledger icon (SF Symbol name)
    var icon: String

    /// Ledger color hex
    var colorHex: String

    /// Whether this is the default ledger
    var isDefault: Bool

    /// Creation timestamp
    var createdAt: Date

    /// Last modified timestamp
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        colorHex: String = "007AFF",
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Predefined Ledgers

extension Ledger {
    /// Default ledger for general expenses
    static func defaultLedger() -> Ledger {
        Ledger(
            name: "日常账本",
            icon: "house.fill",
            colorHex: "007AFF",
            isDefault: true
        )
    }

    /// Predefined ledger templates
    static let templates: [(name: String, icon: String, color: String)] = [
        ("日常账本", "house.fill", "007AFF"),
        ("工作账本", "briefcase.fill", "FF9500"),
        ("旅行账本", "airplane", "34C759"),
        ("家庭账本", "heart.fill", "FF2D55"),
        ("投资账本", "chart.line.uptrend.xyaxis", "AF52DE")
    ]
}

// MARK: - Ledger Manager

/// Manager for multi-ledger operations
final class LedgerManager: ObservableObject {
    /// Shared instance
    static let shared = LedgerManager()

    /// Current active ledger ID
    @Published var currentLedgerID: UUID? {
        didSet {
            if let id = currentLedgerID {
                UserDefaults.standard.set(id.uuidString, forKey: "current_ledger_id")
            }
        }
    }

    private init() {
        // Load saved ledger ID
        if let idString = UserDefaults.standard.string(forKey: "current_ledger_id"),
           let id = UUID(uuidString: idString) {
            currentLedgerID = id
        }
    }

    /// Switch to a different ledger
    func switchTo(_ ledger: Ledger) {
        currentLedgerID = ledger.id
    }
}
