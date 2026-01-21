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

---

## Models

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `Transaction` | `@Model class` | Main transaction data model | `Models/Transaction.swift` |
| `ParsedTransaction` | `struct` | Intermediate parsing result | `Services/Parser/TransactionParser.swift` |
| `SMSTemplate` | `struct` | Bank SMS parsing template | `Services/Parser/BankSMSParser.swift` |
| `ParsedSMS` | `struct` | SMS parsing result | `Services/Parser/BankSMSParser.swift` |

---

## Services (Singleton/Shared)

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `TransactionStore` | `class` | SwiftData transaction management | `Services/Data/TransactionStore.swift` |
| `DeepSeekService` | `class` | DeepSeek API integration | `Services/AI/DeepSeekService.swift` |
| `CategoryEngine` | `class` | Local keywords + AI classification | `Services/AI/CategoryEngine.swift` |
| `TransactionParser` | `struct` | OCR text parser | `Services/Parser/TransactionParser.swift` |
| `BankSMSParser` | `class` | Bank SMS parser | `Services/Parser/BankSMSParser.swift` |

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

---

## App Infrastructure

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `MoneyBuddyApp` | `@main App` | App entry point | `App/MoneyBuddyApp.swift` |
| `URLHandler` | `class` | URL Scheme handler | `App/URLHandler.swift` |

---

## Constants

| Name | Type | Value | Location |
|------|------|-------|----------|
| `appScheme` | `String` | `"moneybuddy"` | `App/URLHandler.swift` |
| `deepSeekAPIURL` | `String` | `"https://api.deepseek.com/chat/completions"` | `Services/AI/DeepSeekService.swift` |

---

## State Variables (View)

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `selectedTab` | `@State Int` | Current tab index | `App/ContentView.swift` |
| `showQuickRecord` | `@State Bool` | Quick record sheet visibility | `App/ContentView.swift` |
| `pendingTransaction` | `@State ParsedTransaction?` | Pending parsed data | `App/ContentView.swift` |

---

*Last updated: Initial creation*
