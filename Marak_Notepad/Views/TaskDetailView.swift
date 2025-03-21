import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var task: Task
    
    @State private var title: String
    @State private var descriptionText: String
    @State private var dueDate: Date?
    @State private var category: String
    @State private var priority: TaskPriority
    @State private var isCompleted: Bool
    
    @State private var isEditing: Bool = false
    @State private var showDueDatePicker: Bool = false
    @State private var showCategoryPicker: Bool = false
    @State private var showPriorityPicker: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    @Query private var categories: [Category]
    
    init(task: Task) {
        self.task = task
        
        // Initialize state with task values
        _title = State(initialValue: task.title)
        _descriptionText = State(initialValue: task.descriptionText)
        _dueDate = State(initialValue: task.dueDate)
        _category = State(initialValue: task.category)
        _priority = State(initialValue: task.priority)
        _isCompleted = State(initialValue: task.isCompleted)
    }
    
    var body: some View {
        Form {
            if isEditing {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if descriptionText.isEmpty {
                            Text("Description")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $descriptionText)
                            .frame(minHeight: 100)
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle(isOn: Binding(
                        get: { dueDate != nil },
                        set: { if !$0 { dueDate = nil } else if dueDate == nil { dueDate = Date() } }
                    )) {
                        Text("Set Due Date")
                    }
                    
                    if dueDate != nil {
                        DatePicker("Due Date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        Text("Uncategorized").tag("Uncategorized")
                        
                        ForEach(categories) { category in
                            Text(category.name).tag(category.name)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(for: priority))
                                    .frame(width: 10, height: 10)
                                
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Status")) {
                    Toggle("Completed", isOn: $isCompleted)
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                        isEditing = false
                        HapticManager.shared.trigger(.success)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.accentColor)
                    
                    Button("Cancel") {
                        // Reset to original values
                        title = task.title
                        descriptionText = task.descriptionText
                        dueDate = task.dueDate
                        category = task.category
                        priority = task.priority
                        isCompleted = task.isCompleted
                        
                        isEditing = false
                        HapticManager.shared.trigger(.light)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.gray)
                }
                
                Section {
                    Button("Delete Task") {
                        showDeleteConfirmation = true
                        HapticManager.shared.trigger(.warning)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                }
            } else {
                // Read-only view
                Section(header: Text("Task Details")) {
                    Text(task.title)
                        .font(.headline)
                    
                    if !task.descriptionText.isEmpty {
                        Text(task.descriptionText)
                            .padding(.top, 4)
                    }
                }
                
                if let dueDate = task.dueDate {
                    Section(header: Text("Due Date")) {
                        HStack {
                            Image(systemName: "calendar")
                            Text(dueDate.fullFormattedString())
                                .foregroundColor(isDueDateCritical(dueDate) ? .red : .primary)
                        }
                    }
                }
                
                Section(header: Text("Category")) {
                    Text(task.category)
                }
                
                Section(header: Text("Priority")) {
                    HStack {
                        Circle()
                            .fill(priorityColor(for: task.priority))
                            .frame(width: 10, height: 10)
                        
                        Text(task.priority.rawValue)
                    }
                }
                
                Section(header: Text("Status")) {
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                        
                        Text(task.isCompleted ? "Completed" : "Not Completed")
                    }
                }
                
                Section(header: Text("Timestamps")) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Created: \(task.createdAt.fullFormattedString())")
                    }
                    
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Modified: \(task.modifiedAt.fullFormattedString())")
                    }
                }
                
                Section {
                    Button("Edit Task") {
                        isEditing = true
                        HapticManager.shared.trigger(.light)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.accentColor)
                    
                    Button(task.isCompleted ? "Mark as Incomplete" : "Mark as Complete") {
                        toggleTaskCompletion()
                        HapticManager.shared.trigger(.success)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(task.isCompleted ? .orange : .green)
                }
                
                Section {
                    Button("Delete Task") {
                        showDeleteConfirmation = true
                        HapticManager.shared.trigger(.warning)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Task" : "Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    private func toggleTaskCompletion() {
        task.isCompleted.toggle()
        task.modifiedAt = Date()
        
        // Update the local state
        isCompleted = task.isCompleted
        
        if task.isCompleted {
            // Cancel notification if task is completed
            NotificationManager.shared.cancelTaskReminder(for: task)
        } else if let dueDate = task.dueDate, dueDate > Date() {
            // Schedule notification if task is marked incomplete and due date is in the future
            NotificationManager.shared.scheduleTaskReminder(for: task)
        }
        
        saveContext()
    }
    
    private func saveChanges() {
        task.updateTask(
            title: title,
            descriptionText: descriptionText,
            dueDate: dueDate,
            category: category,
            priority: priority,
            isCompleted: isCompleted
        )
        
        // Update notification if due date has changed
        if dueDate != nil {
            NotificationManager.shared.scheduleTaskReminder(for: task)
        } else {
            NotificationManager.shared.cancelTaskReminder(for: task)
        }
        
        saveContext()
    }
    
    private func deleteTask() {
        NotificationManager.shared.cancelTaskReminder(for: task)
        modelContext.delete(task)
        saveContext()
        dismiss()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
    private func isDueDateCritical(_ date: Date) -> Bool {
        if date.isOverdue {
            return true
        }
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return date < tomorrow
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