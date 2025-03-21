import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var color: String
    var createdAt: Date
    var tasks: [Task]? = []
    
    init(name: String, color: String = "categoryDefault") {
        self.name = name
        self.color = color
        self.createdAt = Date()
    }
} 