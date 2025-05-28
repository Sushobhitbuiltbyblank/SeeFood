import Foundation
import UIKit
import SwiftUI
import OSLog

@MainActor
class FoodCaptureViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var analyzedItems: [FoodItem] = []
    @Published var isAnalyzing = false
    @Published var error: String?
    
    private let geminiService: MockGeminiService
    private let logger = Logger(subsystem: "com.seefood.app", category: "FoodCaptureViewModel")
    
    init(geminiService: MockGeminiService) {
        self.geminiService = geminiService
    }
    
    func analyzeImage() async {
        guard let image = capturedImage else {
            logger.error("❌ No image available for analysis")
            error = "No image captured"
            return
        }
        
        isAnalyzing = true
        error = nil
        
        do {
            logger.info("🔍 Starting food analysis")
            analyzedItems = try await geminiService.analyzeFood(image: image)
            logger.info("✅ Successfully analyzed food: \(self.analyzedItems.count) items found")
            
            if analyzedItems.isEmpty {
                logger.warning("⚠️ No food items detected in the image")
                error = "No food items detected in the image. Please try again with a clearer photo."
            }
        } catch let geminiError as GeminiError {
            logger.error("❌ Analysis failed: \(geminiError.description)")
            error = geminiError.description
        } catch {
            logger.error("❌ Unexpected error: \(error.localizedDescription)")
            self.error = "An unexpected error occurred. Please try again."
        }
        
        isAnalyzing = false
    }
    
    func clearImage() {
        logger.info("🗑 Clearing current image and analysis")
        capturedImage = nil
        analyzedItems = []
        error = nil
    }
} 
