import Foundation
import SwiftData

// API Response Structure
struct APIFoodItem: Codable {
    let name: String
    let calories: Int?
    let protein: Int?
    let carbs: Int?
    let fats: Int?
}

@Model
final class FoodItem: Codable, Sendable {
    var id: UUID
    var name: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
    
    init(id: UUID = UUID(), name: String, calories: Int = 0, protein: Int = 0, carbs: Int = 0, fats: Int = 0) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
    }
    
    // Create FoodItem from APIFoodItem
    static func from(_ apiItem: APIFoodItem) -> FoodItem {
        FoodItem(
            name: apiItem.name,
            calories: apiItem.calories ?? 0,
            protein: apiItem.protein ?? 0,
            carbs: apiItem.carbs ?? 0,
            fats: apiItem.fats ?? 0
        )
    }
    
    // Codable implementation
    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, carbs, fats
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Int.self, forKey: .protein)
        carbs = try container.decode(Int.self, forKey: .carbs)
        fats = try container.decode(Int.self, forKey: .fats)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(calories, forKey: .calories)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbs, forKey: .carbs)
        try container.encode(fats, forKey: .fats)
    }
} 
