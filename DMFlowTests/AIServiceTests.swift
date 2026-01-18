//
//  AIServiceTests.swift
//  DMFlowTests
//
//  Created by Ronnie Craig
//

import XCTest
@testable import DMFlow

final class AIServiceTests: XCTestCase {

    private let testAPIKey = "test_api_key_12345"

    override func setUp() {
        super.setUp()
        // Clear any existing API key
        AIService.setAPIKey("")
    }

    override func tearDown() {
        // Clean up
        AIService.setAPIKey("")
        super.tearDown()
    }

    // MARK: - API Key Management Tests

    func testSetAndGetAPIKey() {
        AIService.setAPIKey(testAPIKey)

        let retrieved = AIService.getAPIKey()
        XCTAssertEqual(retrieved, testAPIKey)
    }

    func testGetAPIKeyReturnsEmptyWhenNotSet() {
        let retrieved = AIService.getAPIKey()
        XCTAssertEqual(retrieved, "")
    }

    func testSetAPIKeyOverwritesPrevious() {
        AIService.setAPIKey("old_key")
        AIService.setAPIKey("new_key")

        let retrieved = AIService.getAPIKey()
        XCTAssertEqual(retrieved, "new_key")
    }

    // MARK: - User Profile Tests

    func testSetAndGetUserProfile() {
        let profile = UserProfile(
            name: "Test User",
            industry: "Health & Wellness",
            offering: "Nutrition products",
            tone: .friendly,
            emojiUsage: .minimal,
            sampleMessages: "Hey! How are you?"
        )

        AIService.setUserProfile(profile)
        let retrieved = AIService.getUserProfile()

        XCTAssertEqual(retrieved.name, "Test User")
        XCTAssertEqual(retrieved.industry, "Health & Wellness")
        XCTAssertEqual(retrieved.offering, "Nutrition products")
        XCTAssertEqual(retrieved.tone, .friendly)
        XCTAssertEqual(retrieved.emojiUsage, .minimal)
        XCTAssertEqual(retrieved.sampleMessages, "Hey! How are you?")
    }

    func testGetUserProfileReturnsDefaultsWhenNotSet() {
        // Clear UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "profile_name")
        defaults.removeObject(forKey: "profile_industry")
        defaults.removeObject(forKey: "profile_offering")
        defaults.removeObject(forKey: "profile_tone")
        defaults.removeObject(forKey: "profile_emoji")
        defaults.removeObject(forKey: "profile_samples")

        let retrieved = AIService.getUserProfile()

        XCTAssertEqual(retrieved.name, "")
        XCTAssertEqual(retrieved.industry, "")
        XCTAssertEqual(retrieved.offering, "")
        XCTAssertEqual(retrieved.tone, .friendly)
        XCTAssertEqual(retrieved.emojiUsage, .minimal)
        XCTAssertEqual(retrieved.sampleMessages, "")
    }

    // MARK: - TonePreference Tests

    func testTonePreferencePromptDescriptions() {
        XCTAssertEqual(TonePreference.professional.promptDescription, "professional and polished, yet approachable")
        XCTAssertEqual(TonePreference.casual.promptDescription, "casual and relaxed, like texting a friend")
        XCTAssertEqual(TonePreference.friendly.promptDescription, "warm, friendly, and enthusiastic")
        XCTAssertEqual(TonePreference.direct.promptDescription, "straightforward and to-the-point, no fluff")
    }

    // MARK: - EmojiPreference Tests

    func testEmojiPreferencePromptDescriptions() {
        XCTAssertEqual(EmojiPreference.none.promptDescription, "Do NOT use any emojis")
        XCTAssertEqual(EmojiPreference.minimal.promptDescription, "Use emojis sparingly (0-1 per message)")
        XCTAssertEqual(EmojiPreference.moderate.promptDescription, "Use emojis naturally (1-2 per message)")
    }

    // MARK: - AIError Tests

    func testAIErrorDescriptions() {
        XCTAssertNotNil(AIError.noAPIKey.errorDescription)
        XCTAssertNotNil(AIError.proRequired.errorDescription)
        XCTAssertNotNil(AIError.invalidResponse.errorDescription)
        XCTAssertNotNil(AIError.apiError("test error").errorDescription)

        XCTAssertTrue(AIError.apiError("custom message").errorDescription!.contains("custom message"))
    }

    // MARK: - Shared Instance Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(AIService.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = AIService.shared
        let instance2 = AIService.shared
        XCTAssertTrue(instance1 === instance2)
    }
}
