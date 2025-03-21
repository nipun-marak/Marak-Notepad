import Foundation
import SwiftData

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }
    
    var color: String {
        switch self {
        case .low: return "priorityLow"
        case .medium: return "priorityMedium"
        case .high: return "priorityHigh"
        case .urgent: return "priorityUrgent"
        }
    }
}

@Model
final class Task {
    var title: String
    var descriptionText: String
    var dueDate: Date?
    var category: String
    var priority: TaskPriority
    var isCompleted: Bool
    var createdAt: Date
    var modifiedAt: Date
    var orderIndex: Int
    
    init(
        title: String,
        descriptionText: String = "",
        dueDate: Date? = nil,
        category: String = "Uncategorized",
        priority: TaskPriority = .medium,
        isCompleted: Bool = false,
        orderIndex: Int = 0
    ) {
        self.title = title
        self.descriptionText = descriptionText
        self.dueDate = dueDate
        self.category = category
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.orderIndex = orderIndex
    }
    
    func markAsCompleted() {
        isCompleted = true
        modifiedAt = Date()
    }
    
    func updateTask(
        title: String? = nil,
        descriptionText: String? = nil,
        dueDate: Date? = nil,
        category: String? = nil,
        priority: TaskPriority? = nil,
        isCompleted: Bool? = nil,
        orderIndex: Int? = nil
    ) {
        if let title = title {
            self.title = title
        }
        
        if let descriptionText = descriptionText {
            self.descriptionText = descriptionText
        }
        
        if dueDate != self.dueDate {
            self.dueDate = dueDate
        }
        
        if let category = category {
            self.category = category
        }
        
        if let priority = priority {
            self.priority = priority
        }
        
        if let isCompleted = isCompleted {
            self.isCompleted = isCompleted
        }
        
        if let orderIndex = orderIndex {
            self.orderIndex = orderIndex
        }
        
        self.modifiedAt = Date()
    }
} 