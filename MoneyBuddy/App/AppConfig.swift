//
//  AppConfig.swift
//  MoneyBuddy
//
//  Application configuration and initial setup
//

import Foundation

/// Application configuration
enum AppConfig {
    /// Perform initial app setup
    static func initialize() {
        // Set DeepSeek API key if not already set
        if DeepSeekConfig.apiKey.isEmpty {
            DeepSeekConfig.apiKey = "sk-d861c36af2c54d7895b859c2a96521cf"
        }
    }
}
