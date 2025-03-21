import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.orderIndex) private var tasks: [Task]
    
    @State private var viewModel: TaskViewModel
    @State private var searchText = ""
    @State private var isFilterSheetPresented = false
    
    init() {
        // This is a workaround to initialize the viewModel with modelContext
        // We'll properly set it in onAppear
        _viewModel = State(initialValue: TaskViewModel(modelContext: ModelContext(try! ModelContainer(for: Task.self, Category.self))))
    }
    
    var body: some View {
        VStack {
            // Filter bar
            HStack {
                TextField("Search", text: $searchText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.trailing, 8)
                    .onChange(of: searchText) { _, newValue in
                        viewModel.searchText = newValue
                    }
                
                Button {
                    isFilterSheetPresented = true
                    HapticManager.shared.trigger(.light)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            if viewModel.filteredTasks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No tasks found")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    if !searchText.isEmpty || !viewModel.selectedCategories.isEmpty || !viewModel.selectedPriorities.isEmpty {
                        Button {
                            searchText = ""
                            viewModel.searchText = ""
                            viewModel.selectedCategories = []
                            viewModel.selectedPriorities = []
                            viewModel.showCompleted = true
                        } label: {
                            Text("Clear Filters")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.filteredTasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            TaskRowView(task: task) {
                                viewModel.toggleTaskCompletion(task)
                                HapticManager.shared.trigger(.success)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteTask(task)
                                HapticManager.shared.trigger(.error)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                // Mark as completed or incompleted
                                viewModel.toggleTaskCompletion(task)
                                HapticManager.shared.trigger(.success)
                            } label: {
                                Label(
                                    task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                                    systemImage: task.isCompleted ? "xmark.circle" : "checkmark.circle"
                                )
                            }
                            .tint(task.isCompleted ? .orange : .green)
                        }
                    }
                    .onMove { indices, destination in
                        viewModel.reorderTasks(fromOffsets: indices, toOffset: destination)
                        HapticManager.shared.trigger(.medium)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .onAppear {
            // Set up the viewModel with the actual modelContext from environment
            viewModel = TaskViewModel(modelContext: modelContext)
        }
        .sheet(isPresented: $isFilterSheetPresented) {
            FilterView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }
}

struct TaskRowView: View {
    let task: Task
    let toggleCompletion: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Completion button
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            // Task details
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                    .strikethrough(task.isCompleted)
                
                if !task.descriptionText.isEmpty {
                    Text(task.descriptionText)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    // Due date if available
                    if let dueDate = task.dueDate {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            
                            Text(dueDate.relativeDateString())
                                .font(.caption)
                                .foregroundColor(isDueDateCritical(dueDate) ? .red : .secondary)
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                    }
                    
                    // Category
                    Text(task.category)
                        .font(.caption)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Priority indicator
            priorityView(for: task.priority)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private func priorityView(for priority: TaskPriority) -> some View {
        ZStack {
            Circle()
                .fill(priorityColor(for: priority))
                .frame(width: 12, height: 12)
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
    
    private func isDueDateCritical(_ date: Date) -> Bool {
        if date.isOverdue {
            return true
        }
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return date < tomorrow
    }
} 