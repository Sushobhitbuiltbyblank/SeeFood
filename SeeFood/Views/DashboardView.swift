import SwiftUI
import SwiftData
import UIKit
import os

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DailyLogViewModel
    
    //for testing purpose
//    @StateObject private var geminiService = MockGeminiService()
    
    @StateObject private var geminiService = GeminiService(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
    
    @Binding var selectedTab: Int
    @State private var showingImagePicker = false
    @State private var showingSourcePicker = false
    @State private var selectedDateIndex = 1 // 0 for yesterday, 1 for today
    @State private var imageSource: UIImagePickerController.SourceType = .camera
    @State private var showingFoodAnalysis = false
    @State private var capturedImage: UIImage?
    @State private var analyzedItems: [FoodItem] = []
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var mealToEdit: MealEntry?
    
    private let dates = ["Yesterday", "Today"]
    private let logger = Logger(subsystem: "com.seefood.app", category: "DashboardView")
    
    init(modelContext: ModelContext, selectedTab: Binding<Int>) {
        let viewModel = DailyLogViewModel(modelContext: modelContext)
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTab = selectedTab
    }
    
    private var selectedDate: Date {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: selectedDateIndex - 1, to: calendar.startOfDay(for: Date())) ?? Date()
        logger.debug("Selected date index: \(selectedDateIndex), computed date: \(date)")
        return date
    }
    
    private func getCaloriesForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let log = viewModel.allLogs.first(where: { calendar.startOfDay(for: $0.date) == startOfDay }) {
            return log.totalCalories
        }
        return 0
    }
    
    private func getProteinForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let log = viewModel.allLogs.first(where: { calendar.startOfDay(for: $0.date) == startOfDay }) {
            return log.totalProtein
        }
        return 0
    }
    
    private func getCarbsForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let log = viewModel.allLogs.first(where: { calendar.startOfDay(for: $0.date) == startOfDay }) {
            return log.totalCarbs
        }
        return 0
    }
    
    private func getFatsForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let log = viewModel.allLogs.first(where: { calendar.startOfDay(for: $0.date) == startOfDay }) {
            return log.totalFats
        }
        return 0
    }
    
    private func getMealsForDate(_ date: Date) -> [MealEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let log = viewModel.allLogs.first(where: { calendar.startOfDay(for: $0.date) == startOfDay }) {
            return log.meals.sorted(by: { $0.timestamp > $1.timestamp })
        }
        return []
    }
    
    private func analyzeImage(_ image: UIImage) {
        Task { @MainActor in
            isAnalyzing = true
            analysisError = nil
            
            do {
                logger.debug("Starting image analysis with Gemini")
                let items = try await geminiService.analyzeFood(image: image)
                logger.debug("Analysis complete. Found \(items.count) items")
                
                self.analyzedItems = items
                self.capturedImage = image
                self.showingFoodAnalysis = true
                self.isAnalyzing = false
            } catch {
                logger.error("Analysis failed: \(error.localizedDescription)")
                self.analysisError = error.localizedDescription
                self.isAnalyzing = false
            }
        }
    }
    
    private func handleEditMeal(_ meal: MealEntry) {
        // If meal has no image, we'll show an error
        guard let mealImage = meal.image else {
            analysisError = "Cannot edit meal without an image. Please delete and create a new meal instead."
            return
        }
        
        mealToEdit = meal
        capturedImage = mealImage
        analyzedItems = meal.items
        showingFoodAnalysis = true
    }
    
    private func handleDeleteMeal(_ meal: MealEntry) {
        viewModel.deleteMeal(meal)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        DateSelectorView(selectedIndex: $selectedDateIndex, dates: dates)
                        
                        CalorieProgressView(
                            calories: getCaloriesForDate(selectedDate),
                            protein: getProteinForDate(selectedDate),
                            carbs: getCarbsForDate(selectedDate),
                            fats: getFatsForDate(selectedDate),
                            date: dates[selectedDateIndex]
                        )
                        .padding(.horizontal)
                        
                        AnalysisStatusView(
                            isAnalyzing: isAnalyzing,
                            error: analysisError
                        )
                        
                        RecentUploadsView(
                            meals: getMealsForDate(selectedDate),
                            onDelete: handleDeleteMeal
                        )
                    }
                }
                
                AddButtonView(
                    isEnabled: selectedDateIndex == 1,
                    isAnalyzing: isAnalyzing
                ) {
                    if selectedDateIndex == 1 {
                        showingSourcePicker = true
                    } else {
                        logger.debug("Cannot add meals for past dates")
                    }
                }
            }
            .navigationTitle("SeeFood")
            .onAppear {
                viewModel.refresh()
            }
            .onChange(of: selectedDateIndex) { _, _ in
                viewModel.refresh()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imageSource) { image in
                    if let image = image {
                        analyzeImage(image)
                    }
                }
            }
            .sheet(isPresented: $showingFoodAnalysis) {
                if let image = capturedImage {
                    FoodAnalysisView(
                        analyzedImage: image,
                        foodItems: analyzedItems,
                        selectedTab: $selectedTab,
                        mealToEdit: mealToEdit
                    )
                }
            }
            .actionSheet(isPresented: $showingSourcePicker) {
                ActionSheet(
                    title: Text("Add Food"),
                    message: Text("Choose how to add your food"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            imageSource = .camera
                            showingImagePicker = true
                        },
                        .default(Text("Choose from Library")) {
                            imageSource = .photoLibrary
                            showingImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .alert("Analysis Error", isPresented: .constant(analysisError != nil)) {
                Button("OK", role: .cancel) {
                    analysisError = nil
                }
            } message: {
                if let error = analysisError {
                    Text(error)
                }
            }
        }
    }
}

#Preview {
    DashboardView(
        modelContext: ModelContext(try! ModelContainer(for: DailyLog.self)),
        selectedTab: .constant(0)
    )
} 
