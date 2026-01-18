//
//  NotificationService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import UserNotifications
import os.log

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            Log.notifications.error("Authorization error: \(error.localizedDescription)")
            return false
        }
    }

    func scheduleFollowUpReminder(for prospect: Prospect) {
        guard let followUpDate = prospect.nextFollowUp else { return }

        // Cancel any existing reminder first
        cancelFollowUpReminder(for: prospect)

        // Don't schedule if the date is in the past
        let calendar = Calendar.current
        if calendar.startOfDay(for: followUpDate) < calendar.startOfDay(for: Date()) {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Follow-up Reminder"
        content.body = "Time to follow up with \(prospect.name)"
        if prospect.isHotLead {
            content.body = "🔥 Time to follow up with \(prospect.name)"
        }
        content.sound = .default
        content.userInfo = ["prospectId": prospect.id.uuidString]

        // Schedule for 9 AM on the follow-up date
        var components = calendar.dateComponents([.year, .month, .day], from: followUpDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "followup-\(prospect.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Log.notifications.error("Error scheduling notification: \(error.localizedDescription)")
            } else {
                Log.notifications.debug("Scheduled follow-up notification")
            }
        }
    }

    func cancelFollowUpReminder(for prospect: Prospect) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["followup-\(prospect.id.uuidString)"]
        )
    }

    func scheduleMorningReminder(hour: Int, overdueCount: Int, todayCount: Int) {
        guard overdueCount > 0 || todayCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.sound = .default

        var bodyParts: [String] = []
        if overdueCount > 0 {
            bodyParts.append("\(overdueCount) overdue follow-up\(overdueCount == 1 ? "" : "s")")
        }
        if todayCount > 0 {
            bodyParts.append("\(todayCount) follow-up\(todayCount == 1 ? "" : "s") scheduled for today")
        }
        content.body = "You have " + bodyParts.joined(separator: " and ")

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "morning-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Log.notifications.error("Error scheduling morning reminder: \(error.localizedDescription)")
            }
        }
    }

    func cancelMorningReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["morning-reminder"]
        )
    }

    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}
