//
//  URLHandler.swift
//  MoneyBuddy
//
//  URL Scheme handler for receiving data from iOS Shortcuts
//

import Foundation
import SwiftUI
import Combine

/// URL Scheme constants
enum URLScheme {
    static let scheme = "moneybuddy"
    static let ocrRecord = "ocr-record"
    static let smsRecord = "sms-record"
}

/// URL action types
enum URLAction {
    case ocrRecord(text: String)
    case smsRecord(raw: String)
    case unknown
}

/// Observable URL handler for managing incoming URL actions
@MainActor
final class URLHandler: ObservableObject {
    /// Singleton instance
    static let shared = URLHandler()

    /// Current pending action from URL
    @Published var pendingAction: URLAction?

    /// Whether quick record sheet should be shown
    @Published var showQuickRecord: Bool = false

    /// Parsed transaction ready for confirmation
    @Published var parsedTransaction: ParsedTransaction?

    private init() {}

    /// Handle incoming URL
    /// - Parameter url: The URL to handle
    /// - Returns: Whether the URL was handled successfully
    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard url.scheme == URLScheme.scheme else {
            return false
        }

        let action = parseURL(url)
        pendingAction = action

        switch action {
        case .ocrRecord(let text):
            handleOCRRecord(text: text)
        case .smsRecord(let raw):
            handleSMSRecord(raw: raw)
        case .unknown:
            return false
        }

        return true
    }

    /// Parse URL into action
    private func parseURL(_ url: URL) -> URLAction {
        guard let host = url.host else {
            return .unknown
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        switch host {
        case URLScheme.ocrRecord:
            // For OCR, text comes from clipboard
            if let clipboardText = UIPasteboard.general.string {
                return .ocrRecord(text: clipboardText)
            }
            return .unknown

        case URLScheme.smsRecord:
            // For SMS, raw content comes as URL parameter
            if let raw = queryItems.first(where: { $0.name == "raw" })?.value {
                return .smsRecord(raw: raw)
            }
            return .unknown

        default:
            return .unknown
        }
    }

    /// Handle OCR record action
    private func handleOCRRecord(text: String) {
        let parser = TransactionParser()
        parsedTransaction = parser.parse(text)
        showQuickRecord = true
    }

    /// Handle SMS record action
    private func handleSMSRecord(raw: String) {
        let parser = BankSMSParser()
        if let result = parser.parse(raw) {
            parsedTransaction = ParsedTransaction(
                amount: result.amount,
                merchant: result.merchant,
                type: .expense,
                paymentSource: .bank,
                bankName: result.bankName,
                cardSuffix: result.cardSuffix
            )
            showQuickRecord = true
        }
    }

    /// Clear pending action
    func clearPendingAction() {
        pendingAction = nil
        parsedTransaction = nil
        showQuickRecord = false
    }
}
