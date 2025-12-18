//
//  AIService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation

@Observable
final class AIService {
    static let shared = AIService()

    private let apiKey: String? = {
        // API key should be set in environment or config
        // For production, use a secure method like Keychain or server-side proxy
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }()

    var isLoading = false
    var lastError: String?

    private init() {}

    func generateFollowUpMessage(for prospect: Prospect) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIError.noAPIKey
        }

        let canUse = await UsageTracker.shared.canUseAI
        guard canUse else {
            throw AIError.proRequired
        }

        isLoading = true
        defer { isLoading = false }

        let prompt = buildPrompt(for: prospect)
        let message = try await callOpenAI(prompt: prompt)

        return message
    }

    private func buildPrompt(for prospect: Prospect) -> String {
        let stageContext: String
        switch prospect.stage {
        case .new:
            stageContext = "This is a new prospect you haven't reached out to yet. Write an initial outreach message that's friendly and non-salesy."
        case .engaged:
            stageContext = "This prospect has shown interest and you're in active conversation. Write a message that moves toward discussing how you can help them."
        case .presented:
            stageContext = "You've already pitched your product/opportunity. Write a follow-up that addresses potential concerns without being pushy."
        case .followUp:
            stageContext = "This prospect needs nurturing. Write a value-add message that provides something helpful without asking for anything."
        case .client:
            stageContext = "This is a converted client. Write a check-in message to maintain the relationship and ensure they're happy."
        case .dnd:
            stageContext = "This prospect asked not to be contacted. Write a brief, respectful check-in that gives them an easy out."
        }

        var context = """
        You are helping a network marketer write a follow-up DM message.

        Prospect details:
        - Name: \(prospect.name)
        - Platform: \(prospect.platform.displayName)
        - Current stage: \(prospect.stage.displayName)
        """

        if let handle = prospect.handle {
            context += "\n- Handle: @\(handle)"
        }

        if let notes = prospect.notes, !notes.isEmpty {
            context += "\n- Notes: \(notes)"
        }

        context += "\n\n\(stageContext)"

        context += """


        Guidelines:
        - Keep it short (2-3 sentences max)
        - Be conversational and authentic
        - Don't be salesy or use hype words
        - Match the casual tone of \(prospect.platform.displayName)
        - Don't use emojis excessively

        Write only the message, nothing else.
        """

        return context
    }

    private func callOpenAI(prompt: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw AIError.noAPIKey
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 150,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AIError: LocalizedError {
    case noAPIKey
    case proRequired
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "AI features require an API key. Contact support for help."
        case .proRequired:
            return "AI Message Suggestions require DMFlow Pro."
        case .invalidResponse:
            return "Failed to get a response from AI. Please try again."
        case .apiError(let message):
            return "AI error: \(message)"
        }
    }
}
