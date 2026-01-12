//
//  ActivityRowView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI

struct ActivityRowView: View {
    let activity: ProspectActivity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Activity type icon
            ZStack {
                Circle()
                    .fill(activityColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: activity.activityType.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(activityColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.activityType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(formattedTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let notes = activity.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Show metadata for stage changes
                if activity.activityType == .stageChange,
                   let metadata = activity.metadata {
                    if let fromStage = metadata["fromStage"],
                       let toStage = metadata["toStage"] {
                        HStack(spacing: 4) {
                            Text(fromStage)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())

                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(toStage)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var activityColor: Color {
        switch activity.activityType.color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .gray
        }
    }

    private var formattedTime: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(activity.timestamp) {
            return activity.timestamp.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(activity.timestamp) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: activity.timestamp, to: now).day,
                  daysAgo < 7 {
            return "\(daysAgo)d ago"
        } else {
            return activity.timestamp.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

#Preview {
    VStack {
        ActivityRowView(activity: ProspectActivity(
            prospectId: UUID(),
            activityType: .message,
            notes: "Sent follow-up about product samples"
        ))

        ActivityRowView(activity: ProspectActivity(
            prospectId: UUID(),
            activityType: .call,
            timestamp: Date().addingTimeInterval(-86400),
            notes: "Quick check-in call"
        ))

        ActivityRowView(activity: ProspectActivity(
            prospectId: UUID(),
            activityType: .stageChange,
            timestamp: Date().addingTimeInterval(-172800),
            metadata: ["fromStage": "New", "toStage": "Engaged"]
        ))
    }
    .padding()
}
