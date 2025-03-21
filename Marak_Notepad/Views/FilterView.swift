import SwiftUI
import SwiftData

struct FilterView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var localSelectedCategories: [String] = []
    @State private var localSelectedPriorities: [TaskPriority] = []
    @State private var localShowCompleted: Bool = true
    @State private var localSortOption: TaskViewModel.SortOption = .priority
    
    var body: some View {
        NavigationStack {
            List {
                Section("Categories") {
                    ForEach(viewModel.categories, id: \.name) { category in
                        Button {
                            toggleCategory(category.name)
                        } label: {
                            HStack {
                                Text(category.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if localSelectedCategories.contains(category.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    
                    if viewModel.categories.isEmpty {
                        Text("No categories available")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Section("Priority") {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Button {
                            togglePriority(priority)
                        } label: {
                            HStack {
                                priorityLabel(priority)
                                
                                Spacer()
                                
                                if localSelectedPriorities.contains(priority) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section("Completion Status") {
                    Toggle("Show Completed Tasks", isOn: $localShowCompleted)
                }
                
                Section("Sort By") {
                    Picker("Sort Option", selection: $localSortOption) {
                        ForEach(TaskViewModel.SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Filter Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        localSelectedCategories = []
                        localSelectedPriorities = []
                        localShowCompleted = true
                        localSortOption = .priority
                        HapticManager.shared.trigger(.light)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        HapticManager.shared.trigger(.medium)
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initialize local state with current viewModel values
                localSelectedCategories = viewModel.selectedCategories
                localSelectedPriorities = viewModel.selectedPriorities
                localShowCompleted = viewModel.showCompleted
                localSortOption = viewModel.sortOption
            }
        }
    }
    
    private func toggleCategory(_ category: String) {
        if localSelectedCategories.contains(category) {
            localSelectedCategories.removeAll { $0 == category }
        } else {
            localSelectedCategories.append(category)
        }
        HapticManager.shared.trigger(.selection)
    }
    
    private func togglePriority(_ priority: TaskPriority) {
        if localSelectedPriorities.contains(priority) {
            localSelectedPriorities.removeAll { $0 == priority }
        } else {
            localSelectedPriorities.append(priority)
        }
        HapticManager.shared.trigger(.selection)
    }
    
    private func applyFilters() {
        viewModel.selectedCategories = localSelectedCategories
        viewModel.selectedPriorities = localSelectedPriorities
        viewModel.showCompleted = localShowCompleted
        viewModel.sortOption = localSortOption
    }
    
    private func priorityLabel(_ priority: TaskPriority) -> some View {
        HStack {
            Circle()
                .fill(priorityColor(for: priority))
                .frame(width: 10, height: 10)
            
            Text(priority.rawValue)
                .foregroundColor(.primary)
        }
    }
    
    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return .blue
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
} 