import SwiftUI

struct RecentFoodItemView: View {
    let meal: MealEntry
    let timeAgo: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Food Image
            if let image = meal.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }
            
            // Food Details
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.items.first?.name ?? "Unknown")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    MacroText(value: meal.totalCalories, unit: "cal", icon: "flame.fill", color: .red)
                    MacroText(value: meal.totalProtein, unit: "p", icon: "p.circle.fill", color: .purple)
                    MacroText(value: meal.totalCarbs, unit: "c", icon: "c.circle.fill", color: .blue)
                }
            }
            
            Spacer()
            
            // Time and Actions
            VStack(alignment: .trailing, spacing: 8) {
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct MacroText: View {
    let value: Int
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text("\(value)\(unit)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    RecentFoodItemView(
        meal: MealEntry(
            items: [FoodItem(name: "Fetuccini", calories: 450, protein: 12, carbs: 56, fats: 23)],
            mealType: .lunch
        ),
        timeAgo: "2h ago",
        onDelete: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
} 
