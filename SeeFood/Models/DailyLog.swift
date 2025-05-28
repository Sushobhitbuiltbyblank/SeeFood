import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    @Relationship(deleteRule: .cascade) var meals: [MealEntry]
    
    init(id: UUID = UUID(), date: Date = Date(), meals: [MealEntry] = []) {
        self.id = id
        self.date = date
        self.meals = meals
    }
    
    var totalCalories: Int {
        meals.reduce(0) { $0 + $1.totalCalories }
    }
    
    var totalProtein: Int {
        meals.reduce(0) { $0 + $1.totalProtein }
    }
    
    var totalCarbs: Int {
        meals.reduce(0) { $0 + $1.totalCarbs }
    }
    
    var totalFats: Int {
        meals.reduce(0) { $0 + $1.totalFats }
    }
    
    static func fetchOrCreate(for date: Date, context: ModelContext) -> DailyLog {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.date >= startOfDay && log.date < endOfDay
            }
        )
        
        do {
            let existingLogs = try context.fetch(descriptor)
            if let existingLog = existingLogs.first {
                return existingLog
            }
        } catch {
            print("Error fetching daily log: \(error)")
        }
        
        let newLog = DailyLog(date: startOfDay)
        context.insert(newLog)
        return newLog
    }
} 