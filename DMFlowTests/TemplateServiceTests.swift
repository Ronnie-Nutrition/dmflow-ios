//
//  TemplateServiceTests.swift
//  DMFlowTests
//
//  Created by Ronnie Craig
//

import XCTest
@testable import DMFlow

final class TemplateServiceTests: XCTestCase {

    // MARK: - Placeholder Replacement Tests

    func testReplacesNamePlaceholder() {
        let template = "Hey {{name}}! How are you?"
        let prospect = createTestProspect(name: "John Smith")

        let result = TemplateService.shared.replacePlaceholders(template, prospect: prospect)

        XCTAssertEqual(result, "Hey John Smith! How are you?")
    }

    func testReplacesFirstNamePlaceholder() {
        let template = "Hi {{firstName}}, quick question..."
        let prospect = createTestProspect(name: "John Smith")

        let result = TemplateService.shared.replacePlaceholders(template, prospect: prospect)

        XCTAssertEqual(result, "Hi John, quick question...")
    }

    func testHandlesSingleNameForFirstName() {
        let template = "Hey {{firstName}}!"
        let prospect = createTestProspect(name: "Madonna")

        let result = TemplateService.shared.replacePlaceholders(template, prospect: prospect)

        XCTAssertEqual(result, "Hey Madonna!")
    }

    func testReplacesProductPlaceholder() {
        let template = "I help people with {{product}}"
        let prospect = createTestProspect(name: "Test")
        let profile = UserProfile(
            name: "Me",
            industry: "Health",
            offering: "nutrition supplements",
            tone: .friendly,
            emojiUsage: .minimal,
            sampleMessages: ""
        )

        let result = TemplateService.shared.replacePlaceholders(template, prospect: prospect, userProfile: profile)

        XCTAssertEqual(result, "I help people with nutrition supplements")
    }

    func testReplacesProductPlaceholderWithFallback() {
        let template = "I help people with {{product}}"
        let prospect = createTestProspect(name: "Test")
        let profile = UserProfile(
            name: "",
            industry: "",
            offering: "",
            tone: .friendly,
            emojiUsage: .minimal,
            sampleMessages: ""
        )

        let result = TemplateService.shared.replacePlaceholders(template, prospect: prospect, userProfile: profile)

        XCTAssertEqual(result, "I help people with [your product/service]")
    }

    func testReplacesMyNamePlaceholder() {
        let template = "This is {{myName}}"
        let prospect = createTestProspect(name: "Test")
        let profile = UserProfile(
            name: "Sarah Johnson",
            industry: "",
            offering: "",
            tone: .friendly,
            emojiUsage: .minimal,
            sampleMessages: ""
        )

        let result = TemplateService.shared.replacePlaceholders(template, prospect: prospect, userProfile: profile)

        XCTAssertEqual(result, "This is Sarah Johnson")
    }

    func testReplacesMyNamePlaceholderWithFallback() {
        let template = "This is {{myName}}"
        let prospect = createTestProspect(name: "Test")
        let profile = UserProfile(
            name: "",
            industry: "",
            offering: "",
            tone: .friendly,
            emojiUsage: .minimal,
            sampleMessages: ""
        )

        let result = TemplateService.shared.replacePlaceholders(template, prospect: prospect, userProfile: profile)

        XCTAssertEqual(result, "This is [your name]")
    }

    func testReplacesMultiplePlaceholders() {
        let template = "Hey {{firstName}}, I'm {{myName}} and I help people with {{product}}!"
        let prospect = createTestProspect(name: "John Doe")
        let profile = UserProfile(
            name: "Sarah",
            industry: "Health",
            offering: "fitness coaching",
            tone: .friendly,
            emojiUsage: .minimal,
            sampleMessages: ""
        )

        let result = TemplateService.shared.replacePlaceholders(template, prospect: prospect, userProfile: profile)

        XCTAssertEqual(result, "Hey John, I'm Sarah and I help people with fitness coaching!")
    }

    func testPreservesTextWithoutPlaceholders() {
        let template = "This message has no placeholders."
        let prospect = createTestProspect(name: "Test")

        let result = TemplateService.shared.replacePlaceholders(template, prospect: prospect)

        XCTAssertEqual(result, "This message has no placeholders.")
    }

    // MARK: - Built-in Templates Tests

    func testBuiltInTemplatesExist() {
        XCTAssertFalse(TemplateService.builtInTemplates.isEmpty)
    }

    func testBuiltInTemplatesHaveValidContent() {
        for template in TemplateService.builtInTemplates {
            XCTAssertFalse(template.name.isEmpty, "Template name should not be empty")
            XCTAssertFalse(template.content.isEmpty, "Template content should not be empty")
        }
    }

    func testBuiltInTemplatesCoverAllCategories() {
        let categories = Set(TemplateService.builtInTemplates.map { $0.category })

        XCTAssertTrue(categories.contains(.initialOutreach))
        XCTAssertTrue(categories.contains(.followUp))
        XCTAssertTrue(categories.contains(.objectionHandler))
        XCTAssertTrue(categories.contains(.checkIn))
    }

    // MARK: - Placeholder Info Tests

    func testPlaceholderInfoExists() {
        XCTAssertFalse(TemplateService.placeholderInfo.isEmpty)
    }

    func testPlaceholderInfoContainsAllPlaceholders() {
        let placeholders = TemplateService.placeholderInfo.map { $0.placeholder }

        XCTAssertTrue(placeholders.contains("{{name}}"))
        XCTAssertTrue(placeholders.contains("{{firstName}}"))
        XCTAssertTrue(placeholders.contains("{{product}}"))
        XCTAssertTrue(placeholders.contains("{{myName}}"))
    }

    // MARK: - Shared Instance Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(TemplateService.shared)
    }

    // MARK: - Helper Methods

    private func createTestProspect(name: String) -> Prospect {
        Prospect(
            name: name,
            handle: nil,
            platform: .instagram,
            stage: .new,
            nextFollowUp: nil,
            notes: nil,
            isHotLead: false
        )
    }
}
