//
//  CalendarService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import EventKit
import os.log

final class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private let calendarIdentifierKey = "dmflow.calendarIdentifier"
    private let eventIdentifierPrefix = "dmflow-followup-"

    private init() {}

    // MARK: - Authorization

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                return try await eventStore.requestFullAccessToEvents()
            } else {
                return try await eventStore.requestAccess(to: .event)
            }
        } catch {
            Log.calendar.error("Failed to request access: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Calendar Management

    /// Gets or creates the DMFlow calendar
    private func getDMFlowCalendar() -> EKCalendar? {
        // Try to find existing calendar by identifier
        if let identifier = UserDefaults.standard.string(forKey: calendarIdentifierKey),
           let calendar = eventStore.calendar(withIdentifier: identifier) {
            return calendar
        }

        // Try to find by title
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == "DMFlow Follow-Ups" }) {
            UserDefaults.standard.set(existing.calendarIdentifier, forKey: calendarIdentifierKey)
            return existing
        }

        // Create new calendar
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "DMFlow Follow-Ups"

        // Find best source for local calendar
        if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = localSource
        } else if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" }) {
            calendar.source = iCloudSource
        } else if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
            calendar.source = defaultSource
        } else {
            Log.calendar.warning("No suitable calendar source found")
            return nil
        }

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            UserDefaults.standard.set(calendar.calendarIdentifier, forKey: calendarIdentifierKey)
            Log.calendar.info("Created DMFlow calendar")
            return calendar
        } catch {
            Log.calendar.error("Failed to create calendar: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Event Management

    /// Creates or updates a calendar event for a prospect's follow-up
    func syncFollowUp(for prospect: Prospect) {
        guard UserDefaults.standard.bool(forKey: "calendarSyncEnabled") else {
            Log.calendar.debug("Calendar sync disabled, skipping")
            return
        }
        guard authorizationStatus == .fullAccess else {
            Log.calendar.warning("Calendar access not granted. Status: \(String(describing: authorizationStatus.rawValue))")
            return
        }
        guard let followUpDate = prospect.nextFollowUp else {
            // No follow-up date, remove any existing event
            removeFollowUpEvent(for: prospect)
            return
        }

        guard let calendar = getDMFlowCalendar() else {
            Log.calendar.error("Failed to get or create DMFlow calendar")
            return
        }

        let eventIdentifier = "\(eventIdentifierPrefix)\(prospect.id.uuidString)"

        // Try to find existing event
        var event: EKEvent?
        if let storedIdentifier = UserDefaults.standard.string(forKey: eventIdentifier),
           let existingEvent = eventStore.event(withIdentifier: storedIdentifier) {
            event = existingEvent
        }

        // Create new event if not found
        if event == nil {
            event = EKEvent(eventStore: eventStore)
            event?.calendar = calendar
        }

        guard let event = event else { return }

        // Configure event
        event.title = "Follow up with \(prospect.name)"

        var notes = "Platform: \(prospect.platform.displayName)"
        if let handle = prospect.handle, !handle.isEmpty {
            notes += "\nHandle: @\(handle)"
        }
        notes += "\nStage: \(prospect.stage.displayName)"
        if prospect.isHotLead {
            notes += "\n🔥 Hot Lead"
        }
        if let prospectNotes = prospect.notes, !prospectNotes.isEmpty {
            notes += "\n\nNotes: \(prospectNotes)"
        }
        event.notes = notes

        // Set as all-day event on the follow-up date
        let dateCalendar = Calendar.current
        let startOfDay = dateCalendar.startOfDay(for: followUpDate)
        event.startDate = startOfDay
        event.endDate = startOfDay
        event.isAllDay = true

        // Add alert at 9 AM
        event.alarms = [EKAlarm(absoluteDate: dateCalendar.date(bySettingHour: 9, minute: 0, second: 0, of: followUpDate) ?? followUpDate)]

        do {
            try eventStore.save(event, span: .thisEvent)
            UserDefaults.standard.set(event.eventIdentifier, forKey: eventIdentifier)
            Log.calendar.debug("Saved follow-up event for prospect")
        } catch {
            Log.calendar.error("Failed to save event: \(error.localizedDescription)")
        }
    }

    /// Removes the calendar event for a prospect
    func removeFollowUpEvent(for prospect: Prospect) {
        let eventIdentifier = "\(eventIdentifierPrefix)\(prospect.id.uuidString)"

        guard let storedIdentifier = UserDefaults.standard.string(forKey: eventIdentifier),
              let event = eventStore.event(withIdentifier: storedIdentifier) else {
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
            UserDefaults.standard.removeObject(forKey: eventIdentifier)
            Log.calendar.debug("Removed follow-up event for prospect")
        } catch {
            Log.calendar.error("Failed to remove event: \(error.localizedDescription)")
        }
    }

    /// Syncs all prospects with follow-ups to calendar
    func syncAllFollowUps(_ prospects: [Prospect]) {
        Log.calendar.info("Attempting to sync \(prospects.count) prospects to calendar")
        guard UserDefaults.standard.bool(forKey: "calendarSyncEnabled") else {
            Log.calendar.debug("Calendar sync disabled")
            return
        }
        guard authorizationStatus == .fullAccess else {
            Log.calendar.warning("Calendar access not granted. Status: \(String(describing: authorizationStatus.rawValue))")
            return
        }

        for prospect in prospects {
            if prospect.nextFollowUp != nil {
                syncFollowUp(for: prospect)
            }
        }

        Log.calendar.info("Synced \(prospects.filter { $0.nextFollowUp != nil }.count) follow-ups to calendar")
    }

    /// Removes all DMFlow calendar events
    func removeAllEvents() {
        guard let calendar = getDMFlowCalendar() else { return }

        let predicate = eventStore.predicateForEvents(
            withStart: Date.distantPast,
            end: Date.distantFuture,
            calendars: [calendar]
        )

        let events = eventStore.events(matching: predicate)

        for event in events {
            do {
                try eventStore.remove(event, span: .thisEvent)
            } catch {
                Log.calendar.error("Failed to remove event: \(error.localizedDescription)")
            }
        }

        Log.calendar.info("Removed \(events.count) events")
    }
}
