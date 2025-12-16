//
//  StatsViewModel.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import SwiftUI

@Observable
final class StatsViewModel {
    var prospects: [Prospect] = []

    var totalProspects: Int {
        prospects.count
    }

    var activeProspects: Int {
        prospects.filter { $0.stage != .client && $0.stage != .dnd }.count
    }

    var clientCount: Int {
        prospects.filter { $0.stage == .client }.count
    }

    var dndCount: Int {
        prospects.filter { $0.stage == .dnd }.count
    }

    var conversionRate: Double {
        guard totalProspects > 0 else { return 0 }
        return Double(clientCount) / Double(totalProspects) * 100
    }

    var overdueCount: Int {
        prospects.filter { $0.isOverdue && $0.stage != .client && $0.stage != .dnd }.count
    }

    var followUpComplianceRate: Double {
        let withFollowUp = prospects.filter { $0.nextFollowUp != nil && $0.stage != .client && $0.stage != .dnd }
        guard !withFollowUp.isEmpty else { return 100 }
        let onTime = withFollowUp.filter { !$0.isOverdue }.count
        return Double(onTime) / Double(withFollowUp.count) * 100
    }

    func prospectsInStage(_ stage: FunnelStage) -> Int {
        prospects.filter { $0.stage == stage }.count
    }

    func averageDaysInStage(_ stage: FunnelStage) -> Int {
        let prospectsInStage = prospects.filter { $0.stage == stage }
        guard !prospectsInStage.isEmpty else { return 0 }
        let totalDays = prospectsInStage.reduce(0) { $0 + $1.daysInCurrentStage }
        return totalDays / prospectsInStage.count
    }

    func prospectsAddedInPeriod(days: Int) -> Int {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return prospects.filter { $0.createdAt >= startDate }.count
    }

    func conversionsInPeriod(days: Int) -> Int {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return prospects.filter { $0.stage == .client && $0.updatedAt >= startDate }.count
    }

    var platformBreakdown: [(Platform, Int)] {
        Platform.allCases.map { platform in
            (platform, prospects.filter { $0.platform == platform }.count)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }
    }

    var stageBreakdown: [(FunnelStage, Int)] {
        FunnelStage.allCases.map { stage in
            (stage, prospectsInStage(stage))
        }
    }

    var hotLeadCount: Int {
        prospects.filter { $0.isHotLead && $0.stage != .client && $0.stage != .dnd }.count
    }
}
