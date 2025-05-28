import SwiftUI
import Charts

struct DailyLogView: View {
    @ObservedObject var viewModel: DailyLogViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Picker
                    DatePicker(
                        "Select Date",
                        selection: Binding(
                            get: { viewModel.selectedDate },
                            set: { viewModel.selectDate($0) }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    // Daily Summary
                    if let log = viewModel.dailyLog {
                        VStack(spacing: 20) {
                            // Nutrition Summary Cards
                            VStack(spacing: 16) {
                                Text("Daily Summary")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        NutritionCard(title: "Calories", value: log.totalCalories, unit: "cal")
                                        NutritionCard(title: "Protein", value: log.totalProtein, unit: "g")
                                        NutritionCard(title: "Carbs", value: log.totalCarbs, unit: "g")
                                        NutritionCard(title: "Fats", value: log.totalFats, unit: "g")
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            // Meals List
                            VStack(spacing: 16) {
                                Text("Meals")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                LazyVStack(spacing: 16) {
                                    ForEach(log.meals) { meal in
                                        MealCard(meal: meal)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        VStack {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                                .padding()
                            
                            Text("No meals logged for this day")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Daily Log")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

struct NutritionCard: View {
    let title: String
    let value: Int
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.title2)
                .bold()
                .minimumScaleFactor(0.5)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MealCard: View {
    let meal: MealEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formatDate(meal.timestamp))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(meal.mealType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let image = meal.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
            }
            
            VStack(spacing: 12) {
                ForEach(meal.items) { item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("P: \(item.protein)g  C: \(item.carbs)g  F: \(item.fats)g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(item.calories) cal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if item.id != meal.items.last?.id {
                        Divider()
                    }
                }
            }
            
            HStack {
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Total: \(meal.totalCalories) cal")
                        .font(.headline)
                    Text("P: \(meal.totalProtein)g  C: \(meal.totalCarbs)g  F: \(meal.totalFats)g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 
 