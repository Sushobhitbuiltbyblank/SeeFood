import SwiftUI

struct CalorieProgressView: View {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fats: Int
    let maxCalories: Int = 5000
    let maxProtein: Int = 150  // Recommended daily protein intake in grams
    let maxCarbs: Int = 300    // Recommended daily carbs intake in grams
    let maxFats: Int = 65      // Recommended daily fats intake in grams
    let date: String
    
    private var calorieProgress: Double {
        min(Double(calories) / Double(maxCalories), 1.0)
    }
    
    private var proteinProgress: Double {
        min(Double(protein) / Double(maxProtein), 1.0)
    }
    
    private var carbsProgress: Double {
        min(Double(carbs) / Double(maxCarbs), 1.0)
    }
    
    private var fatsProgress: Double {
        min(Double(fats) / Double(maxFats), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(date)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                MacroStatView(
                    value: Int(calorieProgress * 100),
                    current: calories,
                    max: maxCalories,
                    label: "Calories",
                    color: .accentColor,
                    showUnit: false,
                    size: 60
                )
                
                Divider()
                    .frame(height: 40)
                
                HStack(spacing: 20) {
                    MacroStatView(
                        value: Int(proteinProgress * 100),
                        current: protein,
                        max: maxProtein,
                        label: "Protein",
                        color: .purple
                    )
                    MacroStatView(
                        value: Int(carbsProgress * 100),
                        current: carbs,
                        max: maxCarbs,
                        label: "Carbs",
                        color: .blue
                    )
                    MacroStatView(
                        value: Int(fatsProgress * 100),
                        current: fats,
                        max: maxFats,
                        label: "Fats",
                        color: .orange
                    )
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct MacroStatView: View {
    let value: Int
    let current: Int
    let max: Int
    let label: String
    let color: Color
    var showUnit: Bool = true
    var size: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: size * 0.1)
                    .frame(width: size, height: size)
                
                Circle()
                    .trim(from: 0, to: Double(value) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(value)%")
                        .font(size > 40 ? .subheadline : .caption2)
                        .fontWeight(.medium)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(showUnit ? "\(current)g" : "\(current)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if size > 40 {
                Text("\(max - current) left")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    CalorieProgressView(
        calories: 1250,
        protein: 75,
        carbs: 150,
        fats: 40,
        date: "Today"
    )
    .padding()
} 
