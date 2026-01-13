//
//  WidgetService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import WidgetKit

// MARK: - Widget Data Models (shared with widget extension)

struct WidgetProspect: Codable {
    let id: String
    let name: String
    let handle: String?
    let platform: String
    let isHotLead: Bool
    let followUpDate: Date?
}

struct WidgetData: Codable {
    let overdueCount: Int
    let todayCount: Int
    let hotLeadCount: Int
    let totalCount: Int
    let upcomingProspects: [WidgetProspect]
    let lastUpdated: Date
}

// MARK: - Widget Service

final class WidgetService {
    static let shared = WidgetService()
    private let appGroupId = "group.com.ronnie.dmflow"

    private init() {}

    /// Updates the widget with current prospect data
    func updateWidget(with prospects: [Prospect]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculate counts
        let overdueCount = prospects.filter { prospect in
            guard let followUp = prospect.nextFollowUp else { return false }
            return calendar.startOfDay(for: followUp) < today
        }.count

        let todayCount = prospects.filter { prospect in
            guard let followUp = prospect.nextFollowUp else { return false }
            let followUpDay = calendar.startOfDay(for: followUp)
            return followUpDay == today
        }.count

        let hotLeadCount = prospects.filter { $0.isHotLead }.count

        // Get upcoming prospects (overdue + today, sorted by date)
        let upcomingProspects = prospects
            .filter { prospect in
                guard let followUp = prospect.nextFollowUp else { return false }
                let followUpDay = calendar.startOfDay(for: followUp)
                return followUpDay <= today
            }
            .sorted { p1, p2 in
                // Sort: overdue first, then by date, then hot leads first
                let date1 = p1.nextFollowUp ?? Date.distantFuture
                let date2 = p2.nextFollowUp ?? Date.distantFuture
                if date1 != date2 {
                    return date1 < date2
                }
                return p1.isHotLead && !p2.isHotLead
            }
            .prefix(10)
            .map { prospect in
                WidgetProspect(
                    id: prospect.id.uuidString,
                    name: prospect.name,
                    handle: prospect.handle,
                    platform: prospect.platform.rawValue,
                    isHotLead: prospect.isHotLead,
                    followUpDate: prospect.nextFollowUp
                )
            }

        let widgetData = WidgetData(
            overdueCount: overdueCount,
            todayCount: todayCount,
            hotLeadCount: hotLeadCount,
            totalCount: prospects.count,
            upcomingProspects: Array(upcomingProspects),
            lastUpdated: Date()
        )

        // Save to App Group
        saveWidgetData(widgetData)

        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveWidgetData(_ data: WidgetData) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            #if DEBUG
            print("WidgetService: Failed to access App Group UserDefaults")
            #endif
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: "widgetData")
            defaults.synchronize()
            #if DEBUG
            print("WidgetService: Updated widget data - overdue: \(data.overdueCount), today: \(data.todayCount)")
            #endif
        } catch {
            #if DEBUG
            print("WidgetService: Failed to encode widget data: \(error)")
            #endif
        }
    }

    /// Clears the widget data (useful for data reset)
    func clearWidgetData() {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        defaults.removeObject(forKey: "widgetData")
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
