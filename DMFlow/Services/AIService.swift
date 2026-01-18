//
//  AIService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import os.log

// MARK: - User Profile Types

enum TonePreference: String, CaseIterable, Identifiable {
    case professional = "Professional"
    case casual = "Casual"
    case friendly = "Friendly"
    case direct = "Direct"

    var id: String { rawValue }

    var promptDescription: String {
        switch self {
        case .professional: return "professional and polished, yet approachable"
        case .casual: return "casual and relaxed, like texting a friend"
        case .friendly: return "warm, friendly, and enthusiastic"
        case .direct: return "straightforward and to-the-point, no fluff"
        }
    }
}

enum EmojiPreference: String, CaseIterable, Identifiable {
    case none = "None"
    case minimal = "Minimal"
    case moderate = "Moderate"

    var id: String { rawValue }

    var promptDescription: String {
        switch self {
        case .none: return "Do NOT use any emojis"
        case .minimal: return "Use emojis sparingly (0-1 per message)"
        case .moderate: return "Use emojis naturally (1-2 per message)"
        }
    }
}

// MARK: - User Profile

struct UserProfile {
    var name: String
    var industry: String
    var offering: String
    var tone: TonePreference
    var emojiUsage: EmojiPreference
    var sampleMessages: String

    static let empty = UserProfile(
        name: "",
        industry: "",
        offering: "",
        tone: .friendly,
        emojiUsage: .minimal,
        sampleMessages: ""
    )
}

// MARK: - AI Service

@Observable
final class AIService {
    static let shared = AIService()

    private static let apiKeyKeychainKey = "openai_api_key"
    private static let apiKeyUserDefaultsKey = "openai_api_key" // For migration only

    private var apiKey: String? {
        // Check Keychain first, then environment variable as fallback
        if let stored = KeychainService.readString(key: Self.apiKeyKeychainKey), !stored.isEmpty {
            return stored
        }
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }

    // MARK: - API Key Management

    static func setAPIKey(_ key: String) {
        do {
            try KeychainService.save(key: apiKeyKeychainKey, string: key)
            // Clean up old UserDefaults key if it exists
            UserDefaults.standard.removeObject(forKey: apiKeyUserDefaultsKey)
        } catch {
            Log.ai.error("Failed to save API key to Keychain: \(error.localizedDescription)")
        }
    }

    static func getAPIKey() -> String {
        KeychainService.readString(key: apiKeyKeychainKey) ?? ""
    }

    /// Migrates API key from UserDefaults to Keychain (call once at app launch)
    static func migrateAPIKeyIfNeeded() {
        // Check if there's an old key in UserDefaults that needs migration
        if let oldKey = UserDefaults.standard.string(forKey: apiKeyUserDefaultsKey), !oldKey.isEmpty {
            // Only migrate if Keychain doesn't already have a key
            if !KeychainService.exists(key: apiKeyKeychainKey) {
                setAPIKey(oldKey)
            } else {
                // Keychain already has a key, just clean up UserDefaults
                UserDefaults.standard.removeObject(forKey: apiKeyUserDefaultsKey)
            }
        }
    }

    // MARK: - User Profile Management

    static func setUserProfile(_ profile: UserProfile) {
        UserDefaults.standard.set(profile.name, forKey: "profile_name")
        UserDefaults.standard.set(profile.industry, forKey: "profile_industry")
        UserDefaults.standard.set(profile.offering, forKey: "profile_offering")
        UserDefaults.standard.set(profile.tone.rawValue, forKey: "profile_tone")
        UserDefaults.standard.set(profile.emojiUsage.rawValue, forKey: "profile_emoji")
        UserDefaults.standard.set(profile.sampleMessages, forKey: "profile_samples")
    }

    static func getUserProfile() -> UserProfile {
        UserProfile(
            name: UserDefaults.standard.string(forKey: "profile_name") ?? "",
            industry: UserDefaults.standard.string(forKey: "profile_industry") ?? "",
            offering: UserDefaults.standard.string(forKey: "profile_offering") ?? "",
            tone: TonePreference(rawValue: UserDefaults.standard.string(forKey: "profile_tone") ?? "") ?? .friendly,
            emojiUsage: EmojiPreference(rawValue: UserDefaults.standard.string(forKey: "profile_emoji") ?? "") ?? .minimal,
            sampleMessages: UserDefaults.standard.string(forKey: "profile_samples") ?? ""
        )
    }

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
        let profile = AIService.getUserProfile()

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

        // Build user identity section
        var userIdentity = "You are writing a DM message"
        if !profile.name.isEmpty {
            userIdentity = "You are writing as \(profile.name)"
        }
        if !profile.industry.isEmpty {
            userIdentity += ", who works in \(profile.industry)"
        }
        if !profile.offering.isEmpty {
            userIdentity += " and offers \(profile.offering)"
        }
        userIdentity += "."

        // Build sample messages section
        var sampleSection = ""
        if !profile.sampleMessages.isEmpty {
            sampleSection = """

            Here are examples of messages they've written (match this style closely):
            \(profile.sampleMessages)

            """
        }

        var context = """
        \(userIdentity)

        Your communication style is \(profile.tone.promptDescription).
        \(sampleSection)
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
        - Match the tone of \(prospect.platform.displayName)
        - \(profile.emojiUsage.promptDescription)

        Write only the message, nothing else. Match the user's voice and style exactly.
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
