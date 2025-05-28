import Foundation
import UIKit

// MARK: - Protocol
protocol GeminiServiceProtocol {
    func analyzeImage(_ imageData: Data) async throws -> GeminiResponse
}

// MARK: - Mock Implementation
class MockGeminiService: ObservableObject {
    private let decoder = JSONDecoder()
    
    func analyzeFood(image: UIImage) async throws -> [FoodItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        guard let url = Bundle.main.url(forResource: "mock_response", withExtension: "json") else {
            throw GeminiError.invalidResponse
        }
        
        let data = try Data(contentsOf: url)
        let geminiResponse = try decoder.decode(GeminiResponse.self, from: data)
        
        guard let firstCandidate = geminiResponse.candidates.first,
              let firstPart = firstCandidate.content.parts.first,
              let jsonString = extractJSONFromMarkdown(firstPart.text) else {
            throw GeminiError.noValidCandidates
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.invalidJSONFormat
        }
        
        let apiFoodItems = try decoder.decode([APIFoodItem].self, from: jsonData)
        
        if apiFoodItems.isEmpty {
            throw GeminiError.emptyResponse
        }
        
        return apiFoodItems.map { FoodItem.from($0) }
    }
    
    private func extractJSONFromMarkdown(_ text: String) -> String? {
        let pattern = "```json\\s*\\n([\\s\\S]*?)\\n```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, range: range) {
            let matchRange = match.range(at: 1)
            if let substringRange = Range(matchRange, in: text) {
                return String(text[substringRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
} 
