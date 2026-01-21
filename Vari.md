# MoneyBuddy - Variable Registry

> Auto-maintained by development guidelines. Update after every variable change.

---

## Enumerations

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `Category` | `enum: String` | Transaction category types | `Models/Category.swift` |
| `DataSource` | `enum: String` | Data source types (OCR/SMS/CSV/Manual) | `Models/DataSource.swift` |
| `TransactionType` | `enum: String` | Income or expense | `Models/TransactionType.swift` |
| `BankSMS` | `enum: String` | Bank SMS sender numbers | `Services/Parser/BankSMSParser.swift` |
| `PaymentSource` | `enum: String` | Payment platform (WeChat/Alipay) | `Models/PaymentSource.swift` |
| `DeepSeekError` | `enum: Error` | DeepSeek API error types | `Services/AI/DeepSeekService.swift` |
| `ClassificationSource` | `enum` | Source of category classification | `Services/AI/CategoryEngine.swift` |
| `CSVError` | `enum: Error` | CSV import/export errors | `Services/Data/CSVService.swift` |

---

## Models

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `Transaction` | `@Model class` | Main transaction data model | `Models/Transaction.swift` |
| `Ledger` | `@Model class` | Multi-ledger account model | `Models/Ledger.swift` |
| `ParsedTransaction` | `struct` | Intermediate parsing result | `Services/Parser/TransactionParser.swift` |
| `SMSTemplate` | `struct` | Bank SMS parsing template | `Services/Parser/BankSMSParser.swift` |
| `ParsedSMS` | `struct` | SMS parsing result | `Services/Parser/BankSMSParser.swift` |
| `ChatMessage` | `struct` | AI chat message model | `Features/Character/ChatView.swift` |
| `ClassificationResult` | `struct` | Category classification result | `Services/AI/CategoryEngine.swift` |
| `CSVImportResult` | `struct` | CSV import result summary | `Services/Data/CSVService.swift` |
| `MoneyBuddyEntry` | `struct` | Widget timeline entry | `Widget/MoneyBuddyWidget.swift` |

---

## Services (Singleton/Shared)

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `TransactionStore` | `class` | SwiftData transaction management | `Services/Data/TransactionStore.swift` |
| `DeepSeekService` | `class` | DeepSeek API integration | `Services/AI/DeepSeekService.swift` |
| `CategoryEngine` | `class` | Local keywords + AI classification | `Services/AI/CategoryEngine.swift` |
| `TransactionParser` | `struct` | OCR text parser | `Services/Parser/TransactionParser.swift` |
| `BankSMSParser` | `class` | Bank SMS parser | `Services/Parser/BankSMSParser.swift` |
| `CSVService` | `class` | CSV import/export service | `Services/Data/CSVService.swift` |
| `LedgerManager` | `class` | Multi-ledger management | `Models/Ledger.swift` |
| `WidgetDataSync` | `class` | Widget data synchronization | `Widget/MoneyBuddyWidget.swift` |

---

## Views

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `ContentView` | `View` | Main TabView container | `App/ContentView.swift` |
| `DashboardView` | `View` | Transaction list & overview | `Features/Dashboard/DashboardView.swift` |
| `QuickRecordSheet` | `View` | Quick confirmation sheet | `Features/Transaction/QuickRecordSheet.swift` |
| `ManualRecordView` | `View` | Manual entry form | `Features/Transaction/ManualRecordView.swift` |
| `TransactionDetailView` | `View` | Transaction detail view | `Features/Transaction/TransactionDetailView.swift` |
| `AnalyticsView` | `View` | Statistics & charts | `Features/Analytics/AnalyticsView.swift` |
| `WeeklyReportView` | `View` | AI weekly report | `Features/Analytics/WeeklyReportView.swift` |
| `ShortcutGuideView` | `View` | Shortcuts setup guide | `Features/Settings/ShortcutGuideView.swift` |
| `SettingsView` | `View` | App settings | `Features/Settings/SettingsView.swift` |
| `ChatView` | `View` | AI chat interface | `Features/Character/ChatView.swift` |
| `ExportView` | `View` | Data export interface | `Services/Data/CSVService.swift` |
| `ImportView` | `View` | Data import interface | `Services/Data/CSVService.swift` |
| `AboutView` | `View` | About app view | `Features/Settings/SettingsView.swift` |

---

## Widget

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `MoneyBuddyWidget` | `Widget` | iOS widget configuration | `Widget/MoneyBuddyWidget.swift` |
| `MoneyBuddyProvider` | `TimelineProvider` | Widget data provider | `Widget/MoneyBuddyWidget.swift` |
| `SmallWidgetView` | `View` | Small widget layout | `Widget/MoneyBuddyWidget.swift` |
| `MediumWidgetView` | `View` | Medium widget layout | `Widget/MoneyBuddyWidget.swift` |

---

## App Infrastructure

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `MoneyBuddyApp` | `@main App` | App entry point | `App/MoneyBuddyApp.swift` |
| `URLHandler` | `class` | URL Scheme handler | `App/URLHandler.swift` |
| `AppConfig` | `enum` | App configuration & initialization | `App/AppConfig.swift` |
| `DeepSeekConfig` | `enum` | DeepSeek API configuration | `Services/AI/DeepSeekService.swift` |

---

## Constants

| Name | Type | Value | Location |
|------|------|-------|----------|
| `appScheme` | `String` | `"moneybuddy"` | `App/URLHandler.swift` |
| `deepSeekAPIURL` | `String` | `"https://api.deepseek.com/chat/completions"` | `Services/AI/DeepSeekService.swift` |
| `chatModel` | `String` | `"deepseek-chat"` | `Services/AI/DeepSeekService.swift` |
| `reasonerModel` | `String` | `"deepseek-reasoner"` | `Services/AI/DeepSeekService.swift` |

---

## State Variables (View)

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `selectedTab` | `@State Int` | Current tab index | `App/ContentView.swift` |
| `showQuickRecord` | `@State Bool` | Quick record sheet visibility | `App/ContentView.swift` |
| `pendingTransaction` | `@State ParsedTransaction?` | Pending parsed data | `App/ContentView.swift` |
| `messages` | `@State [ChatMessage]` | Chat history | `Features/Character/ChatView.swift` |
| `currentLedgerID` | `@Published UUID?` | Active ledger ID | `Models/Ledger.swift` |

---

## Tests

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `TransactionParserTests` | `XCTestCase` | OCR parser unit tests | `Tests/TransactionParserTests.swift` |
| `BankSMSParserTests` | `XCTestCase` | SMS parser unit tests | `Tests/BankSMSParserTests.swift` |
| `CategoryEngineTests` | `XCTestCase` | Classification engine tests | `Tests/CategoryEngineTests.swift` |
| `CSVServiceTests` | `XCTestCase` | CSV import/export tests | `Tests/CSVServiceTests.swift` |

---

*Last updated: Added P2 features (AI Chat, Widget, Multi-ledger, CSV Import/Export) and unit tests*
