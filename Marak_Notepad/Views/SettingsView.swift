import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    @Query private var categories: [Category]
    @Query private var tasks: [Task]
    
    @State private var showDeleteAllConfirmation = false
    @State private var isShowingCategorySheet = false
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.displayName)
                            }
                            .tag(theme)
                        }
                    }
                    .onChange(of: themeManager.currentTheme) { _, _ in
                        HapticManager.shared.trigger(.light)
                    }
                }
                
                Section("Categories") {
                    ForEach(categories) { category in
                        Button {
                            selectedCategory = category
                            isShowingCategorySheet = true
                        } label: {
                            HStack {
                                Text(category.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(categoryTaskCount(category.name))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Text("Manage Categories")
                    }
                }
                
                Section("Data") {
                    Button("Export Data") {
                        // Future: implement data export
                        HapticManager.shared.trigger(.light)
                    }
                    
                    Button("Import Data") {
                        // Future: implement data import
                        HapticManager.shared.trigger(.light)
                    }
                    
                    Button("Delete All Data") {
                        showDeleteAllConfirmation = true
                        HapticManager.shared.trigger(.warning)
                    }
                    .foregroundColor(.red)
                }
                
                Section("Notifications") {
                    Button("Manage Notification Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete All Data", isPresented: $showDeleteAllConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Are you sure you want to delete all tasks and categories? This action cannot be undone.")
            }
            .sheet(isPresented: $isShowingCategorySheet) {
                if let category = selectedCategory {
                    CategoryDetailView(category: category)
                }
            }
        }
    }
    
    private func categoryTaskCount(_ categoryName: String) -> Int {
        return tasks.filter { $0.category == categoryName }.count
    }
    
    private func deleteAllData() {
        // Delete all tasks
        for task in tasks {
            modelContext.delete(task)
        }
        
        // Delete all categories
        for category in categories {
            modelContext.delete(category)
        }
        
        do {
            try modelContext.save()
            
            // Cancel all notifications
            NotificationManager.shared.cancelAllNotifications()
            
            HapticManager.shared.trigger(.success)
        } catch {
            print("Error deleting all data: \(error.localizedDescription)")
            HapticManager.shared.trigger(.error)
        }
    }
}

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var categories: [Category]
    @Query private var tasks: [Task]
    
    @State private var newCategoryName = ""
    @State private var showDeleteConfirmation = false
    @State private var categoryToDelete: Category?
    
    var body: some View {
        List {
            Section("Add Category") {
                HStack {
                    TextField("New category name", text: $newCategoryName)
                    
                    Button {
                        addCategory()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    .disabled(newCategoryName.isEmpty)
                }
            }
            
            Section("Categories") {
                ForEach(categories) { category in
                    HStack {
                        Text(category.name)
                        
                        Spacer()
                        
                        Text("\(categoryTaskCount(category.name))")
                            .foregroundColor(.secondary)
                        
                        Button {
                            categoryToDelete = category
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if categories.isEmpty {
                    Text("No categories")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle("Manage Categories")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Category", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    deleteCategory(category)
                }
            }
        } message: {
            if let category = categoryToDelete {
                Text("Are you sure you want to delete the category '\(category.name)'? All tasks in this category will be moved to 'Uncategorized'.")
            } else {
                Text("Are you sure you want to delete this category?")
            }
        }
    }
    
    private func addCategory() {
        guard !newCategoryName.isEmpty else { return }
        
        // Check if category already exists
        if categories.contains(where: { $0.name.lowercased() == newCategoryName.lowercased() }) {
            return
        }
        
        let category = Category(name: newCategoryName)
        modelContext.insert(category)
        
        do {
            try modelContext.save()
            newCategoryName = ""
            HapticManager.shared.trigger(.success)
        } catch {
            print("Error adding category: \(error.localizedDescription)")
        }
    }
    
    private func deleteCategory(_ category: Category) {
        // Update all tasks with this category to Uncategorized
        for task in tasks where task.category == category.name {
            task.category = "Uncategorized"
        }
        
        modelContext.delete(category)
        
        do {
            try modelContext.save()
            HapticManager.shared.trigger(.medium)
        } catch {
            print("Error deleting category: \(error.localizedDescription)")
        }
    }
    
    private func categoryTaskCount(_ categoryName: String) -> Int {
        return tasks.filter { $0.category == categoryName }.count
    }
}

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: Category
    
    @Query private var tasks: [Task]
    
    @State private var name: String
    @State private var showDeleteConfirmation = false
    
    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
    }
    
    var filteredTasks: [Task] {
        tasks.filter { $0.category == category.name }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Category Details") {
                    TextField("Name", text: $name)
                    
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty || name == category.name)
                }
                
                Section("Tasks (\(filteredTasks.count))") {
                    if filteredTasks.isEmpty {
                        Text("No tasks in this category")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(filteredTasks) { task in
                            HStack {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isCompleted ? .green : .gray)
                                
                                Text(task.title)
                                    .strikethrough(task.isCompleted)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Delete Category") {
                        showDeleteConfirmation = true
                        HapticManager.shared.trigger(.warning)
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Category Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Category", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteCategory()
                }
            } message: {
                Text("Are you sure you want to delete the category '\(category.name)'? All tasks in this category will be moved to 'Uncategorized'.")
            }
        }
    }
    
    private func saveChanges() {
        guard !name.isEmpty else { return }
        
        // Update category name
        category.name = name
        
        do {
            try modelContext.save()
            HapticManager.shared.trigger(.success)
            dismiss()
        } catch {
            print("Error updating category: \(error.localizedDescription)")
        }
    }
    
    private func deleteCategory() {
        // Update all tasks with this category to Uncategorized
        for task in tasks where task.category == category.name {
            task.category = "Uncategorized"
        }
        
        modelContext.delete(category)
        
        do {
            try modelContext.save()
            HapticManager.shared.trigger(.medium)
            dismiss()
        } catch {
            print("Error deleting category: \(error.localizedDescription)")
        }
    }
} 