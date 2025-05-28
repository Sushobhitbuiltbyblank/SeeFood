import Foundation
import SwiftData
import SwiftUI
import os

@MainActor
class DailyLogViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var dailyLog: DailyLog?
    @Published var allLogs: [DailyLog] = []
    
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.seefood.app", category: "DailyLogViewModel")
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
    }
    
    func selectDate(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
        refresh()
    }
    
    func refresh() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        logger.debug("Refreshing data for date: \(startOfDay)")
        
        // Fetch all logs and filter for the selected date
        let descriptor = FetchDescriptor<DailyLog>()
        
        do {
            let allLogs = try modelContext.fetch(descriptor)
            logger.debug("Fetched \(allLogs.count) total logs")
            
            // Debug print all logs
            for log in allLogs {
                let logDate = calendar.startOfDay(for: log.date)
                logger.debug("Log: \(logDate), meals: \(log.meals.count)")
                
                // Debug meal details
                for meal in log.meals {
                    logger.debug("Meal: \(meal.items.first?.name ?? "unknown"), has image: \(meal.image != nil), timestamp: \(meal.timestamp)")
                }
            }
            
            // Find log for selected date
            let selectedLog = allLogs.first { log in
                let logDate = calendar.startOfDay(for: log.date)
                return logDate == startOfDay
            }
            
            if let existingLog = selectedLog {
                logger.debug("Found existing log with \(existingLog.meals.count) meals")
                dailyLog = existingLog
            } else {
                logger.debug("No log found for \(startOfDay), creating new one")
                let newLog = DailyLog(date: startOfDay)
                modelContext.insert(newLog)
                dailyLog = newLog
            }
            
            // Sort logs by date for the chart view
            self.allLogs = allLogs.sorted { $0.date > $1.date }
            
            try modelContext.save()
            
        } catch {
            logger.error("Error refreshing daily log: \(error.localizedDescription)")
        }
    }
    
    func addMeal(_ meal: MealEntry) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        
        if dailyLog == nil {
            dailyLog = DailyLog(date: startOfDay)
            modelContext.insert(dailyLog!)
        }
        
        dailyLog?.meals.append(meal)
        modelContext.insert(meal)
        
        do {
            try modelContext.save()
            logger.debug("Successfully added meal to \(startOfDay)")
            refresh()
        } catch {
            logger.error("Error saving meal: \(error.localizedDescription)")
        }
    }
    
    func deleteMeal(_ meal: MealEntry) {
        modelContext.delete(meal)
        do {
            try modelContext.save()
            logger.debug("Successfully deleted meal")
            refresh()
        } catch {
            logger.error("Error deleting meal: \(error.localizedDescription)")
        }
    }
    
    func fetchDailyLogs() -> [DailyLog] {
        let descriptor = FetchDescriptor<DailyLog>()
        
        do {
            let logs = try modelContext.fetch(descriptor)
            logger.debug("Fetched \(logs.count) daily logs")
            return logs.sorted { $0.date > $1.date }
        } catch {
            logger.error("Error fetching daily logs: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchCurrentDayLog() -> DailyLog {
        if let log = dailyLog {
            return log
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let descriptor = FetchDescriptor<DailyLog>()
        
        do {
            let allLogs = try modelContext.fetch(descriptor)
            if let existingLog = allLogs.first(where: { calendar.startOfDay(for: $0.date) == startOfDay }) {
                logger.debug("Found existing log with \(existingLog.meals.count) meals")
                return existingLog
            }
        } catch {
            logger.error("Error fetching current day log: \(error.localizedDescription)")
        }
        
        logger.debug("Creating new log for \(startOfDay)")
        let newLog = DailyLog(date: startOfDay)
        modelContext.insert(newLog)
        return newLog
    }
    
    func getMealsByType() -> [MealType: [MealEntry]] {
        let dailyLog = fetchCurrentDayLog()
        var mealsByType: [MealType: [MealEntry]] = [:]
        
        for meal in dailyLog.meals {
            mealsByType[meal.mealType, default: []].append(meal)
        }
        
        return mealsByType
    }
} 
 