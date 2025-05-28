import SwiftUI
import os
import Foundation

// MARK: - Date Selector Component
struct DateSelectorView: View {
    @Binding var selectedIndex: Int
    let dates: [String]
    
    var body: some View {
        Picker("Date", selection: $selectedIndex) {
            ForEach(0..<dates.count, id: \.self) { index in
                Text(dates[index])
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Analysis Status Component
struct AnalysisStatusView: View {
    let isAnalyzing: Bool
    let error: String?
    
    var body: some View {
        VStack {
            if isAnalyzing {
                ProgressView("Analyzing your food...")
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
}

// MARK: - Recent Uploads Component
struct RecentUploadsView: View {
    let meals: [MealEntry]
    @State private var mealToEdit: MealEntry?
    @State private var showingDeleteAlert = false
    @State private var mealToDelete: MealEntry?
    let onDelete: (MealEntry) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently uploaded")
                .font(.headline)
                .padding(.horizontal)
            
            if meals.isEmpty {
                Text("No meals logged for this day")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(meals) { meal in
                        RecentFoodItemView(
                            meal: meal,
                            timeAgo: meal.timestamp.timeAgoDisplay(),
                            onDelete: {
                                mealToDelete = meal
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
        .alert("Delete Meal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                mealToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let meal = mealToDelete {
                    onDelete(meal)
                }
                mealToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this meal? This action cannot be undone.")
        }
    }
}

// MARK: - Add Button Component
struct AddButtonView: View {
    let isEnabled: Bool
    let isAnalyzing: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(isEnabled ? Color.accentColor : Color.gray)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .disabled(!isEnabled || isAnalyzing)
                .padding()
            }
        }
    }
} 
 
