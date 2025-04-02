import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var themeManager = ThemeManager()
    
    @State private var searchText = ""
    @State private var isShowingAddTask = false
    @State private var isShowingSettings = false
    
    var body: some View {
        NavigationStack {
            TaskListView()
                .navigationTitle("Marak Notepad")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isShowingSettings.toggle()
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isShowingAddTask.toggle()
                            HapticManager.shared.trigger(.light)
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddTask) {
                    AddTaskView()
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .environmentObject(themeManager)
        .onAppear {
            // Prefill some data for development/demo purposes
            prefillData()
        }
    }
    
    private func prefillData() {
        // Only add the prefill data if the database is empty
        do {
            let descriptor = FetchDescriptor<Task>()
            let taskCount = try modelContext.fetchCount(descriptor)
            
            if taskCount == 0 {
                // Add default categories
                let workCategory = Category(name: "Work", color: "categoryWork")
                let personalCategory = Category(name: "Personal", color: "categoryPersonal")
                let healthCategory = Category(name: "Health", color: "categoryHealth")
                
                modelContext.insert(workCategory)
                modelContext.insert(personalCategory)
                modelContext.insert(healthCategory)
                
                // Add sample tasks
                let task1 = Task(
                    title: "Complete Project Proposal",
                    descriptionText: "Finish the draft of the Q3 marketing project proposal",
                    dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                    category: "Work",
                    priority: .high,
                    orderIndex: 0
                )
                
                let task2 = Task(
                    title: "Gym Session",
                    descriptionText: "30 min cardio + strength training",
                    dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                    category: "Health",
                    priority: .medium,
                    orderIndex: 1
                )
                
                let task3 = Task(
                    title: "Buy Groceries",
                    descriptionText: "Milk, eggs, bread, vegetables",
                    dueDate: Calendar.current.date(byAdding: .day, value: 0, to: Date()),
                    category: "Personal",
                    priority: .low,
                    orderIndex: 2
                )
                
                let task4 = Task(
                    title: "Call Mom",
                    descriptionText: "Catch up on weekend plans",
                    dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                    category: "Personal",
                    priority: .medium,
                    orderIndex: 3
                )
                
                let task5 = Task(
                    title: "Prepare Presentation",
                    descriptionText: "Gather data and create slides for client meeting",
                    dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                    category: "Work",
                    priority: .urgent,
                    orderIndex: 4
                )
                
                modelContext.insert(task1)
                modelContext.insert(task2)
                modelContext.insert(task3)
                modelContext.insert(task4)
                modelContext.insert(task5)
                
                try modelContext.save()
            }
        } catch {
            print("Error checking or creating sample data: \(error.localizedDescription)")
        }
    }
} 

#Preview {
    ContentView()
}
