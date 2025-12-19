//
//  NotificationService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            #if DEBUG
            print("Notification authorization error: \(error)")
            #endif
            return false
        }
    }

    func scheduleFollowUpReminder(for prospect: Prospect) {
        guard let followUpDate = prospect.nextFollowUp else { return }

        let content = UNMutableNotificationContent()
        content.title = "Follow-up Reminder"
        content.body = "Time to follow up with \(prospect.name)"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["prospectId": prospect.id.uuidString]

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: followUpDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "followup-\(prospect.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
            #endif
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
            #if DEBUG
            if let error = error {
                print("Error scheduling morning reminder: \(error)")
            }
            #endif
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
