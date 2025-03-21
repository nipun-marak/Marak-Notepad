import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var categories: [Category]
    
    @StateObject private var speechRecognitionManager = SpeechRecognitionManager()
    
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(24 * 60 * 60)
    @State private var category = "Uncategorized"
    @State private var priority: TaskPriority = .medium
    
    @State private var isAddingVoice = false
    @State private var isShowingVoiceSheet = false
    @State private var isShowingAddCategory = false
    @State private var newCategoryName = ""
    
    var body: some View {
        NavigationStack {
            Form {
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
                    
                    Button {
                        isShowingVoiceSheet = true
                    } label: {
                        Label("Add with Voice", systemImage: "mic.fill")
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
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
                    
                    Button("Add New Category") {
                        isShowingAddCategory = true
                    }
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
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingVoiceSheet) {
                VoiceInputView(speechRecognitionManager: speechRecognitionManager, onRecognitionComplete: { recognizedText in
                    parseVoiceInput(recognizedText)
                })
                .presentationDetents([.medium])
            }
            .alert("Add New Category", isPresented: $isShowingAddCategory) {
                TextField("Category Name", text: $newCategoryName)
                Button("Cancel", role: .cancel) { newCategoryName = "" }
                Button("Add") {
                    addCategory()
                }
            } message: {
                Text("Enter a name for the new category.")
            }
        }
    }
    
    private func addTask() {
        let newTask = Task(
            title: title,
            descriptionText: descriptionText,
            dueDate: hasDueDate ? dueDate : nil,
            category: category,
            priority: priority
        )
        
        modelContext.insert(newTask)
        
        do {
            try modelContext.save()
            
            // Schedule notification if due date is set
            if hasDueDate {
                NotificationManager.shared.scheduleTaskReminder(for: newTask)
            }
            
            HapticManager.shared.trigger(.success)
            dismiss()
        } catch {
            print("Error saving task: \(error.localizedDescription)")
        }
    }
    
    private func addCategory() {
        guard !newCategoryName.isEmpty else { return }
        
        let category = Category(name: newCategoryName)
        modelContext.insert(category)
        
        do {
            try modelContext.save()
            self.category = newCategoryName
            newCategoryName = ""
        } catch {
            print("Error saving category: \(error.localizedDescription)")
        }
    }
    
    private func parseVoiceInput(_ input: String) {
        guard !input.isEmpty else { return }
        
        // Basic parsing - set the input as the title
        title = input
        
        // Try to extract more information if possible
        // This is a simple example and could be enhanced with natural language processing
        
        // Check for priority keywords
        if input.lowercased().contains("urgent") {
            priority = .urgent
        } else if input.lowercased().contains("high priority") {
            priority = .high
        } else if input.lowercased().contains("low priority") {
            priority = .low
        }
        
        // Check for due date keywords
        if input.lowercased().contains("today") {
            hasDueDate = true
            dueDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(17 * 60 * 60) // 5 PM today
        } else if input.lowercased().contains("tomorrow") {
            hasDueDate = true
            dueDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60 + 17 * 60 * 60) // 5 PM tomorrow
        }
        
        // For categories, check if any existing category is mentioned
        for existingCategory in categories {
            if input.lowercased().contains(existingCategory.name.lowercased()) {
                category = existingCategory.name
                break
            }
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

struct VoiceInputView: View {
    @ObservedObject var speechRecognitionManager: SpeechRecognitionManager
    @Environment(\.dismiss) private var dismiss
    
    var onRecognitionComplete: (String) -> Void
    
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Voice Input")
                .font(.title)
                .padding(.top)
            
            if isRecording {
                Text(speechRecognitionManager.recognizedText)
                    .padding()
                    .frame(minHeight: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Text("Listening...")
                    .foregroundColor(.blue)
                    .padding(.bottom)
                
                Button {
                    stopRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "stop.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                }
                .padding(.bottom)
                
                Text("Tap to stop recording")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                Text("Tap the microphone button to start recording")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                
                Button {
                    startRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "mic.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                }
                .padding(.bottom)
                
                Text("Speak clearly and include details like priority or due date")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    if isRecording {
                        speechRecognitionManager.stopRecording()
                        isRecording = false
                    }
                    dismiss()
                }
                
                Spacer()
                
                Button("Use Text") {
                    if isRecording {
                        stopRecording()
                    }
                    onRecognitionComplete(speechRecognitionManager.recognizedText)
                    dismiss()
                }
                .disabled(speechRecognitionManager.recognizedText.isEmpty)
            }
            .padding()
        }
    }
    
    private func startRecording() {
        // Explicitly specify the concurrency Task
        _Concurrency.Task {
            do {
                try await speechRecognitionManager.startRecording()
                isRecording = true
                HapticManager.shared.trigger(.medium)
            } catch {
                print("Error starting recording: \(error)")
                HapticManager.shared.trigger(.error)
            }
        }
    }
    
    private func stopRecording() {
        speechRecognitionManager.stopRecording()
        isRecording = false
        HapticManager.shared.trigger(.light)
    }
} 
