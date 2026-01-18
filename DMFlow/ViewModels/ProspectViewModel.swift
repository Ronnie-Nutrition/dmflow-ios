//
//  ProspectViewModel.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import SwiftUI
import SwiftData
import os.log

@Observable
final class ProspectViewModel {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addProspect(
        name: String,
        handle: String?,
        platform: Platform,
        stage: FunnelStage,
        nextFollowUp: Date?,
        notes: String?,
        isHotLead: Bool
    ) {
        let prospect = Prospect(
            name: name,
            handle: handle,
            platform: platform,
            stage: stage,
            nextFollowUp: nextFollowUp,
            notes: notes,
            isHotLead: isHotLead
        )
        modelContext.insert(prospect)
        save()
    }

    func deleteProspect(_ prospect: Prospect) {
        modelContext.delete(prospect)
        save()
    }

    func moveToStage(_ prospect: Prospect, stage: FunnelStage) {
        prospect.stage = stage
        prospect.updatedAt = Date()
        save()
    }

    func markAsContacted(_ prospect: Prospect) {
        prospect.lastContact = Date()
        prospect.updatedAt = Date()
        save()
    }

    func toggleHotLead(_ prospect: Prospect) {
        prospect.isHotLead.toggle()
        prospect.updatedAt = Date()
        save()
    }

    func setFollowUp(_ prospect: Prospect, date: Date?) {
        prospect.nextFollowUp = date
        prospect.updatedAt = Date()
        save()
    }

    func snoozeFollowUp(_ prospect: Prospect, days: Int = 1) {
        let newDate = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: prospect.nextFollowUp ?? Date()
        )
        prospect.nextFollowUp = newDate
        prospect.updatedAt = Date()
        save()
    }

    func clearFollowUp(_ prospect: Prospect) {
        prospect.nextFollowUp = nil
        prospect.updatedAt = Date()
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            Log.data.error("Error saving context: \(error.localizedDescription)")
        }
    }
}
