import Foundation

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    let usageMetadata: UsageMetadata
    let modelVersion: String
    let responseId: String
}

struct Candidate: Codable {
    let content: Content
    let finishReason: String
    let avgLogprobs: Double
}

struct Content: Codable {
    let parts: [Part]
    let role: String
}

struct Part: Codable {
    let text: String
}

struct UsageMetadata: Codable {
    let promptTokenCount: Int
    let candidatesTokenCount: Int
    let totalTokenCount: Int
    let promptTokensDetails: [TokenDetail]
    let candidatesTokensDetails: [TokenDetail]
}

struct TokenDetail: Codable {
    let modality: String
    let tokenCount: Int
} 