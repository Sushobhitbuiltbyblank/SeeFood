import SwiftUI
import Charts
import SwiftData
import OSLog

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [DailyLog]
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedNutrient: NutrientType = .calories
    
    private let logger = Logger(subsystem: "com.seefood.app", category: "AnalyticsView")
    
    enum TimeRange: String, CaseIterable {
        case week = "1 Week"
        case twoWeeks = "2 Weeks"
        case month = "1 Month"
        case allTime = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            case .allTime: return 365
            }
        }
    }
    
    enum NutrientType: String, CaseIterable {
        case calories = "Calories"
        case protein = "Protein"
        case carbs = "Carbs"
        case fats = "Fats"
    }
    
    private var filteredData: [(date: Date, calories: Int, protein: Int, carbs: Int, fats: Int)] {
        let calendar = Calendar.current
        let endDate = Date()
        
        return (0..<selectedTimeRange.days).compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: endDate) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            
            if let log = allLogs.first(where: { calendar.startOfDay(for: $0.date) == dayStart }) {
                return (date: date,
                        calories: log.totalCalories,
                        protein: log.totalProtein,
                        carbs: log.totalCarbs,
                        fats: log.totalFats)
            }
            return (date: date, calories: 0, protein: 0, carbs: 0, fats: 0)
        }.reversed()
    }
    
    private var goalProgress: Double {
        let recentCalories = filteredData.last?.calories ?? 0
        return min(Double(recentCalories) / 5000.0, 1.0) // Assuming 5000 calories daily goal
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Goal Progress Card
                    VStack(spacing: 8) {
                        Text("Goal Progress")
                            .font(.headline)
                        
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 10)
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .trim(from: 0, to: goalProgress)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("\(Int(goalProgress * 100))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutrition Trends")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(filteredData, id: \.date) { item in
                                BarMark(
                                    x: .value("Date", item.date, unit: .day),
                                    y: .value("Amount", getValue(for: selectedNutrient, from: item))
                                )
                                .foregroundStyle(getColor(for: selectedNutrient))
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.day())
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Nutrient Type Selector
                    HStack(spacing: 12) {
                        ForEach(NutrientType.allCases, id: \.self) { nutrient in
                            NutrientButton(
                                type: nutrient,
                                isSelected: selectedNutrient == nutrient,
                                action: { selectedNutrient = nutrient }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private func getValue(for nutrientType: NutrientType, from data: (date: Date, calories: Int, protein: Int, carbs: Int, fats: Int)) -> Int {
        switch nutrientType {
        case .calories: return data.calories
        case .protein: return data.protein
        case .carbs: return data.carbs
        case .fats: return data.fats
        }
    }
    
    private func getColor(for nutrientType: NutrientType) -> Color {
        switch nutrientType {
        case .calories: return .accentColor
        case .protein: return .purple
        case .carbs: return .blue
        case .fats: return .orange
        }
    }
}

struct NutrientButton: View {
    let type: AnalyticsView.NutrientType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}

#Preview {
    AnalyticsView()
} 
