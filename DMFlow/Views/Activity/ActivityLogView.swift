//
//  ActivityLogView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct ActivityLogView: View {
    @Environment(\.modelContext) private var modelContext
    let prospect: Prospect

    @Query private var allActivities: [ProspectActivity]

    @State private var showingAddActivity = false

    init(prospect: Prospect) {
        self.prospect = prospect
        // Filter activities for this prospect, sorted by newest first
        let prospectId = prospect.id
        _allActivities = Query(
            filter: #Predicate<ProspectActivity> { activity in
                activity.prospectId == prospectId
            },
            sort: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with add button
            HStack {
                Label("Activity Log", systemImage: "clock.arrow.circlepath")
                    .font(.headline)

                Spacer()

                Button {
                    showingAddActivity = true
                } label: {
                    Label("Log", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }

            if allActivities.isEmpty {
                emptyState
            } else {
                activityList
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView(prospect: prospect)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.questionmark")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No activity logged yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showingAddActivity = true
            } label: {
                Text("Log First Activity")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var activityList: some View {
        VStack(spacing: 0) {
            // Show up to 5 recent activities
            ForEach(Array(allActivities.prefix(5))) { activity in
                ActivityRowView(activity: activity)

                if activity.id != allActivities.prefix(5).last?.id {
                    Divider()
                        .padding(.leading, 48)
                }
            }

            // Show "View All" if more than 5
            if allActivities.count > 5 {
                Divider()
                    .padding(.leading, 48)

                NavigationLink {
                    FullActivityLogView(prospect: prospect)
                } label: {
                    HStack {
                        Spacer()
                        Text("View All (\(allActivities.count))")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

/// Full-screen view for all activities
struct FullActivityLogView: View {
    let prospect: Prospect

    @Query private var activities: [ProspectActivity]

    init(prospect: Prospect) {
        self.prospect = prospect
        let prospectId = prospect.id
        _activities = Query(
            filter: #Predicate<ProspectActivity> { activity in
                activity.prospectId == prospectId
            },
            sort: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    var body: some View {
        List {
            ForEach(groupedActivities, id: \.key) { date, dayActivities in
                Section(header: Text(sectionHeader(for: date))) {
                    ForEach(dayActivities) { activity in
                        ActivityRowView(activity: activity)
                    }
                }
            }
        }
        .navigationTitle("Activity History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var groupedActivities: [(key: Date, value: [ProspectActivity])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: activities) { activity in
            calendar.startOfDay(for: activity.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func sectionHeader(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ActivityLogView(prospect: Prospect(name: "John Smith"))
        }
        .padding()
        .background(Color(.systemGray6))
    }
    .modelContainer(for: [Prospect.self, ProspectActivity.self], inMemory: true)
}
