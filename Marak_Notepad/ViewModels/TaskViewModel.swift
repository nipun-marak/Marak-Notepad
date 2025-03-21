import Foundation
import SwiftData
import Combine

class TaskViewModel: ObservableObject {
    private let modelContext: ModelContext
    private let notificationManager = NotificationManager.shared
    
    @Published var tasks: [Task] = []
    @Published var categories: [Category] = []
    @Published var filteredTasks: [Task] = []
    
    @Published var searchText: String = ""
    @Published var selectedCategories: [String] = []
    @Published var selectedPriorities: [TaskPriority] = []
    @Published var showCompleted: Bool = true
    @Published var sortOption: SortOption = .priority
    
    private var cancellables = Set<AnyCancellable>()
    
    enum SortOption: String, CaseIterable {
        case priority = "Priority"
        case dueDate = "Due Date"
        case creationDate = "Creation Date"
        case alphabetical = "Alphabetical"
        case manual = "Manual Order"
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSubscriptions()
        fetchTasks()
        fetchCategories()
    }
    
    private func setupSubscriptions() {
        // Combine search, filter, and sort options to update the filtered tasks
        Publishers.CombineLatest4(
            $searchText,
            $selectedCategories,
            $selectedPriorities,
            $showCompleted
        )
        .combineLatest($sortOption)
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.applyFiltersAndSort()
        }
        .store(in: &cancellables)
    }
    
    func fetchTasks() {
        do {
            let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor(\.orderIndex, order: .forward)])
            tasks = try modelContext.fetch(descriptor)
            applyFiltersAndSort()
        } catch {
            print("Error fetching tasks: \(error.localizedDescription)")
        }
    }
    
    func fetchCategories() {
        do {
            let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
            categories = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching categories: \(error.localizedDescription)")
        }
    }
    
    func createTask(title: String, description: String = "", dueDate: Date? = nil, category: String = "Uncategorized", priority: TaskPriority = .medium) {
        let newTask = Task(
            title: title,
            descriptionText: description,
            dueDate: dueDate,
            category: category,
            priority: priority,
            orderIndex: tasks.count
        )
        
        modelContext.insert(newTask)
        
        do {
            try modelContext.save()
            
            // Schedule notification if due date is set
            if let dueDate = dueDate {
                notificationManager.scheduleTaskReminder(for: newTask)
            }
            
            fetchTasks()
        } catch {
            print("Error saving task: \(error.localizedDescription)")
        }
    }
    
    func updateTask(_ task: Task, title: String? = nil, description: String? = nil, dueDate: Date? = nil, category: String? = nil, priority: TaskPriority? = nil, isCompleted: Bool? = nil) {
        task.updateTask(
            title: title,
            descriptionText: description,
            dueDate: dueDate,
            category: category,
            priority: priority,
            isCompleted: isCompleted
        )
        
        do {
            try modelContext.save()
            
            // Update notification if due date has changed
            if dueDate != nil {
                notificationManager.scheduleTaskReminder(for: task)
            }
            
            fetchTasks()
        } catch {
            print("Error updating task: \(error.localizedDescription)")
        }
    }
    
    func deleteTask(_ task: Task) {
        notificationManager.cancelTaskReminder(for: task)
        modelContext.delete(task)
        
        do {
            try modelContext.save()
            fetchTasks()
        } catch {
            print("Error deleting task: \(error.localizedDescription)")
        }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        let newCompletionStatus = !task.isCompleted
        task.isCompleted = newCompletionStatus
        task.modifiedAt = Date()
        
        do {
            try modelContext.save()
            
            // Cancel notification if task is completed
            if newCompletionStatus {
                notificationManager.cancelTaskReminder(for: task)
            } else if let dueDate = task.dueDate, dueDate > Date() {
                notificationManager.scheduleTaskReminder(for: task)
            }
            
            fetchTasks()
        } catch {
            print("Error toggling task completion: \(error.localizedDescription)")
        }
    }
    
    func createCategory(name: String, color: String = "categoryDefault") {
        guard !categories.contains(where: { $0.name.lowercased() == name.lowercased() }) else {
            return
        }
        
        let newCategory = Category(name: name, color: color)
        modelContext.insert(newCategory)
        
        do {
            try modelContext.save()
            fetchCategories()
        } catch {
            print("Error saving category: \(error.localizedDescription)")
        }
    }
    
    func deleteCategory(_ category: Category) {
        // Update all tasks with this category to Uncategorized
        for task in tasks where task.category == category.name {
            task.category = "Uncategorized"
        }
        
        modelContext.delete(category)
        
        do {
            try modelContext.save()
            fetchCategories()
            fetchTasks()
        } catch {
            print("Error deleting category: \(error.localizedDescription)")
        }
    }
    
    func reorderTasks(fromOffsets: IndexSet, toOffset: Int) {
        var tasksToReorder = filteredTasks
        tasksToReorder.move(fromOffsets: fromOffsets, toOffset: toOffset)
        
        // Update orderIndex for all affected tasks
        for (index, task) in tasksToReorder.enumerated() {
            task.orderIndex = index
        }
        
        do {
            try modelContext.save()
            fetchTasks()
        } catch {
            print("Error reordering tasks: \(error.localizedDescription)")
        }
    }
    
    private func applyFiltersAndSort() {
        var filtered = tasks
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.lowercased().contains(searchText.lowercased()) ||
                task.descriptionText.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply category filter
        if !selectedCategories.isEmpty {
            filtered = filtered.filter { selectedCategories.contains($0.category) }
        }
        
        // Apply priority filter
        if !selectedPriorities.isEmpty {
            filtered = filtered.filter { selectedPriorities.contains($0.priority) }
        }
        
        // Apply completion filter
        if !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Apply sorting
        switch sortOption {
        case .priority:
            filtered.sort { (task1, task2) -> Bool in
                if task1.priority.sortOrder == task2.priority.sortOrder {
                    return task1.orderIndex < task2.orderIndex
                }
                return task1.priority.sortOrder > task2.priority.sortOrder
            }
        case .dueDate:
            filtered.sort { (task1, task2) -> Bool in
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 < date2
            }
        case .creationDate:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .alphabetical:
            filtered.sort { $0.title.lowercased() < $1.title.lowercased() }
        case .manual:
            filtered.sort { $0.orderIndex < $1.orderIndex }
        }
        
        filteredTasks = filtered
    }
    
    func searchSuggestions(for text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        
        var suggestions = Set<String>()
        
        // Get words from task titles and descriptions
        for task in tasks {
            let titleWords = task.title.components(separatedBy: .whitespacesAndNewlines)
            let descriptionWords = task.descriptionText.components(separatedBy: .whitespacesAndNewlines)
            
            for word in titleWords + descriptionWords where word.count > 2 {
                if word.lowercased().contains(text.lowercased()) {
                    suggestions.insert(word)
                }
            }
        }
        
        return Array(suggestions).sorted().prefix(5).map { $0 }
    }
}