import Foundation
import UIKit
import OSLog

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol { }

enum GeminiError: Error {
    case invalidImage
    case networkError(Error)
    case invalidResponse
    case decodingError
    case httpError(Int)
    case emptyResponse
    case invalidJSONFormat
    case noValidCandidates
    
    var description: String {
        switch self {
        case .invalidImage:
            return "Failed to process image"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .emptyResponse:
            return "No food items detected in the image"
        case .invalidJSONFormat:
            return "Invalid response format from AI model"
        case .noValidCandidates:
            return "No valid response from the AI model"
        }
    }
}

class GeminiService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent"
    private let logger = Logger(subsystem: "com.seefood.app", category: "GeminiService")
    private let session: URLSessionProtocol
    private let imageOptimizer: ImageOptimizer
    
    init(apiKey: String, session: URLSessionProtocol = URLSession.shared, imageOptimizer: ImageOptimizer = ImageOptimizer()) {
        self.apiKey = apiKey
        self.session = session
        self.imageOptimizer = imageOptimizer
    }
    
    private func extractJSONFromMarkdown(_ text: String) -> String? {
        // Find content between ```json and ```
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
    
    func analyzeFood(image: UIImage) async throws -> [FoodItem] {
        // Optimize image before sending
        let (optimizedImage, imageData) = try imageOptimizer.optimizeImage(image)
        
        let base64Image = imageData.base64EncodedString()
        
        // Define generation config values
        let temperature: Double = 0.1
        let topP: Double = 1.0
        let topK: Int = 32
        let maxOutputTokens: Int = 2048
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": """
                            Analyze this food image and provide nutritional information in a structured JSON format.
                            Return the response in this exact format:
                            [
                                {
                                    "name": "food item name",
                                    "calories": number,
                                    "protein": number in grams,
                                    "carbs": number in grams,
                                    "fats": number in grams
                                }
                            ]
                            Be precise and return only the JSON array.
                            """
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generation_config": [
                "temperature": temperature,
                "top_p": topP,
                "top_k": topK,
                "max_output_tokens": maxOutputTokens
            ]
        ]
        
        // Construct URL with API key as query parameter
        guard var urlComponents = URLComponents(string: baseURL) else {
            logger.error("❌ Invalid base URL")
            throw GeminiError.invalidResponse
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            logger.error("❌ Failed to construct URL with API key")
            throw GeminiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            // Log request details (excluding API key for security)
            logger.info("📤 API Request:")
            logger.info("URL: \(self.baseURL)?key=<REDACTED>")
            logger.info("Method: \(request.httpMethod ?? "POST")")
            logger.info("Headers: \(request.allHTTPHeaderFields ?? [:])")
            logger.info("Request body size: \(jsonData.count) bytes")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("❌ Invalid response type")
                throw GeminiError.invalidResponse
            }
            
            // Log response details
            logger.info("📥 API Response:")
            logger.info("Status Code: \(httpResponse.statusCode)")
            logger.info("Headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                logger.info("Response Body: \(responseString)")
            }
            
            // Check HTTP status code
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("❌ HTTP Error: \(httpResponse.statusCode)")
                throw GeminiError.httpError(httpResponse.statusCode)
            }
            
            // First decode the Gemini response structure
            let decoder = JSONDecoder()
            do {
                let geminiResponse = try decoder.decode(GeminiResponse.self, from: data)
                
                // Get the first candidate's text
                guard let firstCandidate = geminiResponse.candidates.first,
                      let firstPart = firstCandidate.content.parts.first,
                      let jsonString = extractJSONFromMarkdown(firstPart.text) else {
                    logger.error("❌ No valid candidates in response")
                    throw GeminiError.noValidCandidates
                }
                
                logger.info("📝 Extracted JSON: \(jsonString)")
                
                // Parse the JSON string into APIFoodItems
                guard let jsonData = jsonString.data(using: .utf8) else {
                    logger.error("❌ Failed to convert JSON string to data")
                    throw GeminiError.invalidJSONFormat
                }
                
                do {
                    // First decode to APIFoodItems
                    let apiFoodItems = try decoder.decode([APIFoodItem].self, from: jsonData)
                    
                    if apiFoodItems.isEmpty {
                        logger.warning("⚠️ No food items detected")
                        throw GeminiError.emptyResponse
                    }
                    
                    // Convert APIFoodItems to FoodItems
                    let foodItems = apiFoodItems.map { FoodItem.from($0) }
                    
                    logger.info("✅ Successfully parsed \(foodItems.count) food items")
                    
                    // After successful analysis, save the optimized image
                    if let firstItem = foodItems.first {
                        do {
                            let imageUrl = try imageOptimizer.saveImage(optimizedImage, forMealId: firstItem.id)
                            logger.info("Saved analyzed image to: \(imageUrl)")
                        } catch {
                            logger.error("Failed to save analyzed image: \(error.localizedDescription)")
                            // Continue even if image saving fails
                        }
                    }
                    
                    return foodItems
                    
                } catch {
                    logger.error("❌ Failed to decode food items: \(error)")
                    logger.error("❌ JSON string that failed to decode: \(jsonString)")
                    throw GeminiError.decodingError
                }
                
            } catch {
                logger.error("❌ Decoding Error: \(error.localizedDescription)")
                if let geminiError = error as? GeminiError {
                    throw geminiError
                }
                throw GeminiError.decodingError
            }
        } catch {
            if let geminiError = error as? GeminiError {
                logger.error("❌ Gemini Error: \(geminiError.description)")
            } else {
                logger.error("❌ Network Error: \(error.localizedDescription)")
            }
            throw error
        }
    }
} 
