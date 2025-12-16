//
//  Prospect.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import SwiftData

@Model
final class Prospect {
    var id: UUID
    var name: String
    var handle: String?
    var platform: Platform
    var stage: FunnelStage
    var lastContact: Date
    var nextFollowUp: Date?
    var notes: String?
    var isHotLead: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        handle: String? = nil,
        platform: Platform = .instagram,
        stage: FunnelStage = .new,
        lastContact: Date = Date(),
        nextFollowUp: Date? = nil,
        notes: String? = nil,
        isHotLead: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.platform = platform
        self.stage = stage
        self.lastContact = lastContact
        self.nextFollowUp = nextFollowUp
        self.notes = notes
        self.isHotLead = isHotLead
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isOverdue: Bool {
        guard let followUp = nextFollowUp else { return false }
        return followUp < Calendar.current.startOfDay(for: Date())
    }

    var isDueToday: Bool {
        guard let followUp = nextFollowUp else { return false }
        return Calendar.current.isDateInToday(followUp)
    }

    var daysSinceLastContact: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastContact, to: Date())
        return components.day ?? 0
    }

    var daysInCurrentStage: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: updatedAt, to: Date())
        return components.day ?? 0
    }

    func moveToNextStage() {
        if let nextStage = stage.next {
            stage = nextStage
            updatedAt = Date()
        }
    }

    func moveToPreviousStage() {
        if let previousStage = stage.previous {
            stage = previousStage
            updatedAt = Date()
        }
    }

    func markContacted() {
        lastContact = Date()
        updatedAt = Date()
    }
}
