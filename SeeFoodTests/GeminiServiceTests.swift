import XCTest
@testable import SeeFood

final class GeminiServiceTests: XCTestCase {
    var sut: GeminiService! // system under test
    
    override func setUp() {
        super.setUp()
        sut = GeminiService(apiKey: "test_api_key")
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Mock Data
    
    let mockGeminiResponse = """
    {
      "candidates": [
        {
          "content": {
            "parts": [
              {
                "text": "```json\\n[\\n  {\\n    \\"name\\": \\"Cheese Pizza\\",\\n    \\"calories\\": 250,\\n    \\"protein\\": 12,\\n    \\"carbs\\": 30,\\n    \\"fats\\": 10\\n  }\\n]\\n```\\n"
              }
            ],
            "role": "model"
          },
          "finishReason": "STOP",
          "avgLogprobs": -0.0096899424829790665
        }
      ],
      "usageMetadata": {
        "promptTokenCount": 346,
        "candidatesTokenCount": 62,
        "totalTokenCount": 408,
        "promptTokensDetails": [
          {
            "modality": "TEXT",
            "tokenCount": 88
          },
          {
            "modality": "IMAGE",
            "tokenCount": 258
          }
        ],
        "candidatesTokensDetails": [
          {
            "modality": "TEXT",
            "tokenCount": 62
          }
        ]
      },
      "modelVersion": "gemini-1.5-flash",
      "responseId": "lBgyaLn9KbLA698P_9u3WA"
    }
    """
    
    // MARK: - Mock URLSession
    
    class MockURLSession: URLSessionProtocol {
        var mockData: Data?
        var mockResponse: URLResponse?
        var mockError: Error?
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            if let error = mockError {
                throw error
            }
            
            guard let data = mockData,
                  let response = mockResponse else {
                throw GeminiError.invalidResponse
            }
            
            return (data, response)
        }
    }
    
    // MARK: - Tests
    
    func testSuccessfulFoodAnalysis() async throws {
        // Given
        let mockSession = MockURLSession()
        mockSession.mockData = mockGeminiResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Create a test image
        let testImage = UIImage(systemName: "photo")!
        
        // Create service with mock session
        sut = GeminiService(apiKey: "test_api_key", session: mockSession)
        
        // When
        let foodItems = try await sut.analyzeFood(image: testImage)
        
        // Then
        XCTAssertEqual(foodItems.count, 1)
        let foodItem = foodItems[0]
        XCTAssertEqual(foodItem.name, "Cheese Pizza")
        XCTAssertEqual(foodItem.calories, 250)
        XCTAssertEqual(foodItem.protein, 12)
        XCTAssertEqual(foodItem.carbs, 30)
        XCTAssertEqual(foodItem.fats, 10)
    }
    
    func testInvalidResponse() async {
        // Given
        let mockSession = MockURLSession()
        mockSession.mockData = "Invalid JSON".data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Create service with mock session
        sut = GeminiService(apiKey: "test_api_key", session: mockSession)
        
        // When/Then
        do {
            let testImage = UIImage(systemName: "photo")!
            _ = try await sut.analyzeFood(image: testImage)
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertTrue(error is GeminiError)
        }
    }
    
    func testHTTPError() async {
        // Given
        let mockSession = MockURLSession()
        mockSession.mockData = mockGeminiResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Create service with mock session
        sut = GeminiService(apiKey: "test_api_key", session: mockSession)
        
        // When/Then
        do {
            let testImage = UIImage(systemName: "photo")!
            _ = try await sut.analyzeFood(image: testImage)
            XCTFail("Expected error but got success")
        } catch GeminiError.httpError(let code) {
            XCTAssertEqual(code, 401)
        } catch {
            XCTFail("Expected HTTP error but got \(error)")
        }
    }
    
    func testEmptyResponse() async {
        // Given
        let mockSession = MockURLSession()
        let emptyResponse = """
        {
          "candidates": [
            {
              "content": {
                "parts": [
                  {
                    "text": "```json\\n[]\\n```\\n"
                  }
                ],
                "role": "model"
              },
              "finishReason": "STOP"
            }
          ]
        }
        """
        mockSession.mockData = emptyResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Create service with mock session
        sut = GeminiService(apiKey: "test_api_key", session: mockSession)
        
        // When/Then
        do {
            let testImage = UIImage(systemName: "photo")!
            _ = try await sut.analyzeFood(image: testImage)
            XCTFail("Expected error but got success")
        } catch GeminiError.emptyResponse {
            // Success
        } catch {
            XCTFail("Expected empty response error but got \(error)")
        }
    }
}
