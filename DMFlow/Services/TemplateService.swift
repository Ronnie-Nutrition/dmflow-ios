//
//  TemplateService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import SwiftData

@Observable
final class TemplateService {
    static let shared = TemplateService()

    private init() {}

    // MARK: - Built-in Templates

    static let builtInTemplates: [(name: String, category: TemplateCategory, content: String)] = [
        // Initial Outreach
        (
            name: "Friendly Introduction",
            category: .initialOutreach,
            content: "Hey {{name}}! I noticed we have some mutual connections and thought I'd reach out. I help people with {{product}} - would love to connect!"
        ),
        (
            name: "Value-First Approach",
            category: .initialOutreach,
            content: "Hi {{name}}, I came across your profile and love what you're doing! I have some ideas that might help with your goals. Mind if I share?"
        ),

        // Follow-Up
        (
            name: "Gentle Check-In",
            category: .followUp,
            content: "Hey {{name}}, just wanted to follow up on our last chat. Any questions I can answer for you?"
        ),
        (
            name: "Value Add",
            category: .followUp,
            content: "Hi {{name}}! Thought of you when I saw this tip. How's everything going?"
        ),

        // Objection Handlers
        (
            name: "Price Concern",
            category: .objectionHandler,
            content: "I totally understand, {{name}}. What if I showed you how it could actually save you money in the long run? Would that help?"
        ),
        (
            name: "Timing Concern",
            category: .objectionHandler,
            content: "No rush at all, {{name}}! When would be a better time to revisit this? I'll follow up then."
        ),

        // Check-In
        (
            name: "Client Appreciation",
            category: .checkIn,
            content: "Hey {{name}}! Just wanted to check in and see how everything is going. Let me know if you need anything!"
        )
    ]

    // MARK: - Populate Built-in Templates

    func populateBuiltInTemplates(in context: ModelContext) {
        // Check if templates already exist
        let descriptor = FetchDescriptor<MessageTemplate>(
            predicate: #Predicate { $0.isBuiltIn == true }
        )

        do {
            let existingBuiltIns = try context.fetch(descriptor)
            if !existingBuiltIns.isEmpty {
                // Built-in templates already exist
                return
            }
        } catch {
            #if DEBUG
            print("Error checking for existing templates: \(error)")
            #endif
        }

        // Create built-in templates
        for template in Self.builtInTemplates {
            let newTemplate = MessageTemplate(
                name: template.name,
                category: template.category,
                content: template.content,
                isBuiltIn: true
            )
            context.insert(newTemplate)
        }

        do {
            try context.save()
        } catch {
            #if DEBUG
            print("Error saving built-in templates: \(error)")
            #endif
        }
    }

    // MARK: - Placeholder Replacement

    /// Replaces placeholders in a template with actual values
    /// Supported placeholders: {{name}}, {{firstName}}, {{product}}, {{myName}}
    func replacePlaceholders(_ template: String, prospect: Prospect, userProfile: UserProfile? = nil) -> String {
        var result = template

        // Prospect placeholders
        result = result.replacingOccurrences(of: "{{name}}", with: prospect.name)
        result = result.replacingOccurrences(of: "{{firstName}}", with: firstName(from: prospect.name))

        // User profile placeholders
        let profile = userProfile ?? AIService.getUserProfile()
        if !profile.offering.isEmpty {
            result = result.replacingOccurrences(of: "{{product}}", with: profile.offering)
        } else {
            // Remove placeholder if no product set
            result = result.replacingOccurrences(of: "{{product}}", with: "[your product/service]")
        }

        if !profile.name.isEmpty {
            result = result.replacingOccurrences(of: "{{myName}}", with: profile.name)
        } else {
            result = result.replacingOccurrences(of: "{{myName}}", with: "[your name]")
        }

        return result
    }

    /// Extracts the first name from a full name
    private func firstName(from fullName: String) -> String {
        fullName.components(separatedBy: " ").first ?? fullName
    }

    // MARK: - Placeholder Info

    /// Returns information about available placeholders for display in UI
    static let placeholderInfo: [(placeholder: String, description: String)] = [
        ("{{name}}", "Prospect's full name"),
        ("{{firstName}}", "Prospect's first name"),
        ("{{product}}", "Your product/service (from profile)"),
        ("{{myName}}", "Your name (from profile)")
    ]
}
