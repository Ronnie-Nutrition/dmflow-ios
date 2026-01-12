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

    init(
        id: UUID = UUID(),
        name: String,
        category: TemplateCategory,
        content: String,
        isBuiltIn: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.content = content
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Preview of the template content (first 50 characters)
    var preview: String {
        if content.count <= 50 {
            return content
        }
        return String(content.prefix(50)) + "..."
    }
}
