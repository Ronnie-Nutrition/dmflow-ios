//
//  FunnelStage.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import SwiftUI

enum FunnelStage: String, Codable, CaseIterable, Identifiable {
    case new
    case engaged
    case presented
    case followUp
    case client
    case dnd

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .new: return "New"
        case .engaged: return "Engaged"
        case .presented: return "Presented"
        case .followUp: return "Follow-Up"
        case .client: return "Client"
        case .dnd: return "DND"
        }
    }

    var description: String {
        switch self {
        case .new: return "First contact made"
        case .engaged: return "Active conversation"
        case .presented: return "Shared info"
        case .followUp: return "Waiting on decision"
        case .client: return "Converted!"
        case .dnd: return "Do Not Disturb"
        }
    }

    var color: Color {
        switch self {
        case .new: return AppColors.primary
        case .engaged: return Color.purple
        case .presented: return Color.orange
        case .followUp: return AppColors.warning
        case .client: return AppColors.success
        case .dnd: return AppColors.danger
        }
    }

    var icon: String {
        switch self {
        case .new: return "star.fill"
        case .engaged: return "bubble.left.and.bubble.right.fill"
        case .presented: return "doc.text.fill"
        case .followUp: return "clock.fill"
        case .client: return "checkmark.circle.fill"
        case .dnd: return "hand.raised.fill"
        }
    }

    var order: Int {
        switch self {
        case .new: return 0
        case .engaged: return 1
        case .presented: return 2
        case .followUp: return 3
        case .client: return 4
        case .dnd: return 5
        }
    }

    var next: FunnelStage? {
        let stages = FunnelStage.allCases.filter { $0 != .dnd }
        guard let currentIndex = stages.firstIndex(of: self),
              currentIndex < stages.count - 1 else { return nil }
        return stages[currentIndex + 1]
    }

    var previous: FunnelStage? {
        let stages = FunnelStage.allCases.filter { $0 != .dnd }
        guard let currentIndex = stages.firstIndex(of: self),
              currentIndex > 0 else { return nil }
        return stages[currentIndex - 1]
    }

    static var activeStages: [FunnelStage] {
        allCases.filter { $0 != .client && $0 != .dnd }
    }

    static var pipelineStages: [FunnelStage] {
        [.new, .engaged, .presented, .followUp, .client]
    }
}
