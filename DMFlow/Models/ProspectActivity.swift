//
//  ProspectActivity.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import SwiftData

/// Represents a logged interaction or activity with a prospect
@Model
final class ProspectActivity {
    var id: UUID
    var prospectId: UUID
    var activityType: ActivityType
    var timestamp: Date
    var notes: String?
    var metadata: [String: String]?

    init(
        id: UUID = UUID(),
        prospectId: UUID,
        activityType: ActivityType,
        timestamp: Date = Date(),
        notes: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.prospectId = prospectId
        self.activityType = activityType
        self.timestamp = timestamp
        self.notes = notes
        self.metadata = metadata
    }
}

/// Types of activities that can be logged for a prospect
enum ActivityType: String, Codable, CaseIterable, Identifiable {
    case message = "message"
    case call = "call"
    case meeting = "meeting"
    case note = "note"
    case stageChange = "stage_change"
    case contacted = "contacted"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .message: return "Message"
        case .call: return "Call"
        case .meeting: return "Meeting"
        case .note: return "Note"
        case .stageChange: return "Stage Change"
        case .contacted: return "Contacted"
        }
    }

    var icon: String {
        switch self {
        case .message: return "message.fill"
        case .call: return "phone.fill"
        case .meeting: return "person.2.fill"
        case .note: return "note.text"
        case .stageChange: return "arrow.right.circle.fill"
        case .contacted: return "checkmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .message: return "blue"
        case .call: return "green"
        case .meeting: return "purple"
        case .note: return "orange"
        case .stageChange: return "indigo"
        case .contacted: return "teal"
        }
    }

    /// Activity types available for manual logging
    static var loggableTypes: [ActivityType] {
        [.message, .call, .meeting, .note]
    }
}
