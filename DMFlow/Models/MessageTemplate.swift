//
//  MessageTemplate.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import SwiftData

enum TemplateCategory: String, Codable, CaseIterable, Identifiable {
    case initialOutreach = "Initial Outreach"
    case followUp = "Follow-Up"
    case objectionHandler = "Objection Handler"
    case checkIn = "Check-In"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .initialOutreach: return "hand.wave.fill"
        case .followUp: return "arrow.uturn.forward"
        case .objectionHandler: return "shield.fill"
        case .checkIn: return "heart.fill"
        case .custom: return "star.fill"
        }
    }

    var order: Int {
        switch self {
        case .initialOutreach: return 0
        case .followUp: return 1
        case .objectionHandler: return 2
        case .checkIn: return 3
        case .custom: return 4
        }
    }
}

@Model
final class MessageTemplate {
    var id: UUID
    var name: String
    var category: TemplateCategory
    var content: String
    var isBuiltIn: Bool
    var createdAt: Date
    var updatedAt: Date

    // A/B Script Tracking
    var timesSent: Int = 0
    var timesConverted: Int = 0
    var variantGroup: UUID? = nil
    var variantLetter: String? = nil

    init(
        id: UUID = UUID(),
        name: String,
        category: TemplateCategory,
        content: String,
        isBuiltIn: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        timesSent: Int = 0,
        timesConverted: Int = 0,
        variantGroup: UUID? = nil,
        variantLetter: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.content = content
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.timesSent = timesSent
        self.timesConverted = timesConverted
        self.variantGroup = variantGroup
        self.variantLetter = variantLetter
    }

    /// Preview of the template content (first 50 characters)
    var preview: String {
        if content.count <= 50 {
            return content
        }
        return String(content.prefix(50)) + "..."
    }

    /// Conversion rate as a percentage (0-100)
    var conversionRate: Double {
        guard timesSent > 0 else { return 0 }
        return Double(timesConverted) / Double(timesSent) * 100
    }

    /// Display name with variant letter if applicable
    var displayName: String {
        if let letter = variantLetter {
            return "\(name) (\(letter))"
        }
        return name
    }

    /// Whether this template is part of an A/B test
    var isVariant: Bool {
        variantGroup != nil
    }
}
