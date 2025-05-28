import SwiftUI
import SwiftData

struct FoodAnalysisView: View {
    let analyzedImage: UIImage
    let foodItems: [FoodItem]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int
    @State private var selectedServings: Int = 1
    @State private var healthScore: Int = 7
    @State private var selectedMealType: MealType = .other
    @State private var showingSaveError = false
    @State private var errorMessage = ""
    let mealToEdit: MealEntry?
    
    init(analyzedImage: UIImage, foodItems: [FoodItem], selectedTab: Binding<Int>, mealToEdit: MealEntry? = nil) {
        self.analyzedImage = analyzedImage
        self.foodItems = foodItems
        self._selectedTab = selectedTab
        self.mealToEdit = mealToEdit
        
        // Set initial values if editing a meal
        if let meal = mealToEdit {
            _selectedMealType = State(initialValue: meal.mealType)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Image Section
                    Image(uiImage: analyzedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                    
                    // Meal Type Picker
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Text(mealType.rawValue).tag(mealType)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Food Items Section
                    ForEach(foodItems) { item in
                        FoodItemCard(foodItem: item, servings: $selectedServings)
                    }
                    
                    // Nutrition Facts
                    NutritionFactsCard(foodItems: foodItems, servings: selectedServings)
                    
                    // Health Score
                    HealthScoreView(score: healthScore)
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button("Fix Results") {
                            // TODO: Implement edit functionality
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Done") {
                            saveMealEntry()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error Saving Meal", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveMealEntry() {
        do {
            // Create adjusted items based on servings
            let adjustedItems = foodItems.map { item in
                let adjustedItem = FoodItem(
                    name: item.name,
                    calories: item.calories * selectedServings,
                    protein: item.protein * selectedServings,
                    carbs: item.carbs * selectedServings,
                    fats: item.fats * selectedServings
                )
                modelContext.insert(adjustedItem)
                return adjustedItem
            }
            
            if let existingMeal = mealToEdit {
                // Update existing meal
                existingMeal.items = adjustedItems
                existingMeal.mealType = selectedMealType
                
                // Only update image if we have a valid one
                if let imageData = analyzedImage.jpegData(compressionQuality: 0.7) {
                    existingMeal.imageData = imageData
                }
            } else {
                // Create new meal entry
                let mealEntry = MealEntry(
                    timestamp: Date(),
                    items: adjustedItems,
                    mealType: selectedMealType
                )
                
                // Set the image
                if let imageData = analyzedImage.jpegData(compressionQuality: 0.7) {
                    mealEntry.imageData = imageData
                }
                
                // Get today's start
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                
                // Use the DailyLog helper method to fetch or create today's log
                let todayLog = DailyLog.fetchOrCreate(for: today, context: modelContext)
                
                // Add meal to today's log and insert it
                todayLog.meals.append(mealEntry)
                modelContext.insert(mealEntry)
            }
            
            // Save all changes
            try modelContext.save()
            print("✅ Successfully saved meal entry")
            dismiss()
            
        } catch {
            print("❌ Error saving meal entry: \(error.localizedDescription)")
            errorMessage = "Failed to save meal: \(error.localizedDescription)"
            showingSaveError = true
        }
    }
}

struct FoodItemCard: View {
    let foodItem: FoodItem
    @Binding var servings: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(foodItem.name)
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                NutrientLabel(icon: "flame.fill", value: "\(foodItem.calories * servings)", unit: "Cal", color: .red)
                NutrientLabel(icon: "chart.pie.fill", value: "\(foodItem.carbs * servings)", unit: "g", color: .orange)
                NutrientLabel(icon: "bolt.fill", value: "\(foodItem.protein * servings)", unit: "g", color: .purple)
                NutrientLabel(icon: "drop.fill", value: "\(foodItem.fats * servings)", unit: "g", color: .blue)
            }
            
            HStack {
                Text("Servings")
                    .foregroundColor(.secondary)
                Spacer()
                ServingsStepper(value: $servings)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct NutrientLabel: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ServingsStepper: View {
    @Binding var value: Int
    
    var body: some View {
        HStack {
            Button(action: { if value > 1 { value -= 1 } }) {
                Image(systemName: "minus")
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            Text("\(value)")
                .frame(width: 40)
                .font(.title3)
            
            Button(action: { value += 1 }) {
                Image(systemName: "plus")
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
    }
}

struct NutritionFactsCard: View {
    let foodItems: [FoodItem]
    let servings: Int
    
    var totalCalories: Int {
        foodItems.reduce(0) { $0 + $1.calories } * servings
    }
    
    var totalProtein: Int {
        foodItems.reduce(0) { $0 + $1.protein } * servings
    }
    
    var totalCarbs: Int {
        foodItems.reduce(0) { $0 + $1.carbs } * servings
    }
    
    var totalFats: Int {
        foodItems.reduce(0) { $0 + $1.fats } * servings
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Facts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            NutritionRow(label: "Calories", value: "\(totalCalories)")
            NutritionRow(label: "Protein", value: "\(totalProtein)g")
            NutritionRow(label: "Carbohydrates", value: "\(totalCarbs)g")
            NutritionRow(label: "Fats", value: "\(totalFats)g")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct HealthScoreView: View {
    let score: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Health Score")
                .font(.headline)
            
            HStack(spacing: 2) {
                ForEach(0..<10) { index in
                    Rectangle()
                        .fill(index < score ? Color.green : Color(.systemGray4))
                        .frame(height: 8)
                }
            }
            
            Text("\(score)/10")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
} 
 
