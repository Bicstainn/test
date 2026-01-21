//
//  CategoryManagementView.swift
//  MoneyBuddy
//
//  Category management - add, edit, delete custom categories
//

import SwiftUI

/// User custom category model
struct CustomCategory: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var isSystem: Bool  // System categories cannot be deleted

    init(id: UUID = UUID(), name: String, icon: String, colorHex: String, isSystem: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isSystem = isSystem
    }
}

/// Category manager for custom categories
final class CustomCategoryManager: ObservableObject {
    static let shared = CustomCategoryManager()

    @Published var categories: [CustomCategory] = []

    private let storageKey = "custom_categories"

    private init() {
        loadCategories()
    }

    /// Load categories from UserDefaults
    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CustomCategory].self, from: data) {
            categories = decoded
        } else {
            // Initialize with system categories
            categories = Self.systemCategories
            saveCategories()
        }
    }

    /// Save categories to UserDefaults
    func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Add a new category
    func add(_ category: CustomCategory) {
        categories.append(category)
        saveCategories()
    }

    /// Update an existing category
    func update(_ category: CustomCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }

    /// Delete a category
    func delete(_ category: CustomCategory) {
        guard !category.isSystem else { return }  // Cannot delete system categories
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }

    /// Reset to default categories
    func resetToDefaults() {
        categories = Self.systemCategories
        saveCategories()
    }

    /// System default categories
    static let systemCategories: [CustomCategory] = [
        CustomCategory(name: "餐饮", icon: "fork.knife", colorHex: "FF6B6B", isSystem: true),
        CustomCategory(name: "交通", icon: "car.fill", colorHex: "4ECDC4", isSystem: true),
        CustomCategory(name: "购物", icon: "cart.fill", colorHex: "45B7D1", isSystem: true),
        CustomCategory(name: "娱乐", icon: "gamecontroller.fill", colorHex: "96CEB4", isSystem: true),
        CustomCategory(name: "住房", icon: "house.fill", colorHex: "DDA0DD", isSystem: true),
        CustomCategory(name: "医疗", icon: "cross.case.fill", colorHex: "FF8C94", isSystem: true),
        CustomCategory(name: "教育", icon: "book.fill", colorHex: "A8E6CF", isSystem: true),
        CustomCategory(name: "收入", icon: "yensign.circle.fill", colorHex: "88D8B0", isSystem: true),
        CustomCategory(name: "其他", icon: "ellipsis.circle.fill", colorHex: "B8B8B8", isSystem: true)
    ]
}

/// Category management view
struct CategoryManagementView: View {
    @ObservedObject var manager = CustomCategoryManager.shared

    @State private var showAddSheet = false
    @State private var editingCategory: CustomCategory?
    @State private var showResetAlert = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // System categories
                Section("系统分类") {
                    ForEach(manager.categories.filter { $0.isSystem }) { category in
                        CategoryRow(category: category)
                            .onTapGesture {
                                editingCategory = category
                            }
                    }
                }

                // Custom categories
                Section("自定义分类") {
                    ForEach(manager.categories.filter { !$0.isSystem }) { category in
                        CategoryRow(category: category)
                            .onTapGesture {
                                editingCategory = category
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    manager.delete(category)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }

                    Button {
                        showAddSheet = true
                    } label: {
                        Label("添加分类", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                // Reset section
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("恢复默认分类", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("分类管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                CategoryEditSheet(mode: .add) { newCategory in
                    manager.add(newCategory)
                }
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditSheet(mode: .edit(category)) { updatedCategory in
                    manager.update(updatedCategory)
                }
            }
            .alert("恢复默认", isPresented: $showResetAlert) {
                Button("恢复", role: .destructive) {
                    manager.resetToDefaults()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要恢复默认分类吗？所有自定义分类将被删除。")
            }
        }
    }
}

/// Category row view
struct CategoryRow: View {
    let category: CustomCategory

    var body: some View {
        HStack(spacing: 12) {
            // Icon with color
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: category.colorHex))
                .cornerRadius(8)

            // Name
            Text(category.name)
                .font(.body)

            Spacer()

            // System badge
            if category.isSystem {
                Text("系统")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(4)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
}

/// Category edit sheet
struct CategoryEditSheet: View {
    enum Mode {
        case add
        case edit(CustomCategory)

        var title: String {
            switch self {
            case .add: return "添加分类"
            case .edit: return "编辑分类"
            }
        }
    }

    let mode: Mode
    let onSave: (CustomCategory) -> Void

    @State private var name: String = ""
    @State private var selectedIcon: String = "tag.fill"
    @State private var selectedColor: String = "007AFF"

    @Environment(\.dismiss) private var dismiss

    /// Available icons
    private let icons = [
        "tag.fill", "star.fill", "heart.fill", "bag.fill", "gift.fill",
        "airplane", "bus.fill", "tram.fill", "bicycle", "fuelpump.fill",
        "cup.and.saucer.fill", "wineglass.fill", "birthday.cake.fill",
        "film.fill", "music.note", "sportscourt.fill", "figure.walk",
        "pawprint.fill", "leaf.fill", "drop.fill", "bolt.fill",
        "phone.fill", "desktopcomputer", "tv.fill", "headphones",
        "creditcard.fill", "banknote.fill", "building.2.fill"
    ]

    /// Available colors
    private let colors = [
        "FF6B6B", "4ECDC4", "45B7D1", "96CEB4", "DDA0DD",
        "FF8C94", "A8E6CF", "88D8B0", "FFD93D", "6BCB77",
        "4D96FF", "FF6B6B", "C9B1FF", "F97316", "007AFF"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Name
                Section("名称") {
                    TextField("分类名称", text: $name)
                }

                // Icon picker
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Color picker
                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .opacity(selectedColor == color ? 1 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Preview
                Section("预览") {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color(hex: selectedColor))
                            .cornerRadius(8)

                        Text(name.isEmpty ? "分类名称" : name)
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if case .edit(let category) = mode {
                    name = category.name
                    selectedIcon = category.icon
                    selectedColor = category.colorHex
                }
            }
        }
    }

    private func saveCategory() {
        let category: CustomCategory
        switch mode {
        case .add:
            category = CustomCategory(name: name, icon: selectedIcon, colorHex: selectedColor)
        case .edit(let existing):
            category = CustomCategory(
                id: existing.id,
                name: name,
                icon: selectedIcon,
                colorHex: selectedColor,
                isSystem: existing.isSystem
            )
        }
        onSave(category)
        dismiss()
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    CategoryManagementView()
}
