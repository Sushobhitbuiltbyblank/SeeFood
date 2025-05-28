import Foundation
import SwiftData
import UIKit

@Model
final class MealEntry {
    var id: UUID
    var timestamp: Date
    @Relationship(deleteRule: .cascade) var items: [FoodItem]
    var mealType: MealType
    var imageData: Data?  // Store image as Data
    
    init(id: UUID = UUID(), timestamp: Date = Date(), items: [FoodItem] = [], mealType: MealType = .other, imageData: Data? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.items = items
        self.mealType = mealType
        self.imageData = imageData
    }
    
    var totalCalories: Int {
        items.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Int {
        items.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Int {
        items.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFats: Int {
        items.reduce(0) { $0 + $1.fats }
    }
    
    // Helper method to get UIImage from stored data
    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    // Helper method to set image
    func setImage(_ image: UIImage?) {
        self.imageData = image?.jpegData(compressionQuality: 0.7)
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case other = "Other"
} 
 