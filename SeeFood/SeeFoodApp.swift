//
//  SeeFoodApp.swift
//  SeeFood
//
//  Created by Sushobhit Jain on 24/05/25.
//

import SwiftUI
import SwiftData

@main
struct SeeFoodApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [DailyLog.self, MealEntry.self, FoodItem.self])
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dailyLogViewModel: DailyLogViewModel
    @State private var selectedTab = 0
    
    init() {
        let viewModel = DailyLogViewModel(modelContext: ModelContext(try! ModelContainer(for: DailyLog.self, MealEntry.self, FoodItem.self)))
        _dailyLogViewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                modelContext: modelContext,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(0)
            
            DailyLogView(viewModel: dailyLogViewModel)
                .tabItem {
                    Label("Daily Log", systemImage: "calendar")
                }
                .tag(1)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.xyaxis.line")
                }
                .tag(2)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 1 {  // When switching to DailyLog tab
                dailyLogViewModel.refresh()
            }
        }
    }
}

#Preview {
    ContentView()
}
