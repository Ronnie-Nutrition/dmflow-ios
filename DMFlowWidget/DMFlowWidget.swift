//
//  DMFlowWidget.swift
//  DMFlowWidget
//
//  Created by Ronnie Craig
//

import WidgetKit
import SwiftUI

// MARK: - Widget Data Model

struct WidgetProspect: Codable, Identifiable {
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

    static var placeholder: WidgetData {
        WidgetData(
            overdueCount: 2,
            todayCount: 3,
            hotLeadCount: 1,
            totalCount: 15,
            upcomingProspects: [
                WidgetProspect(id: "1", name: "John Smith", handle: "johnsmith", platform: "instagram", isHotLead: true, followUpDate: Date()),
                WidgetProspect(id: "2", name: "Sarah Jones", handle: "sarahj", platform: "facebook", isHotLead: false, followUpDate: Date())
            ],
            lastUpdated: Date()
        )
    }

    static var empty: WidgetData {
        WidgetData(
            overdueCount: 0,
            todayCount: 0,
            hotLeadCount: 0,
            totalCount: 0,
            upcomingProspects: [],
            lastUpdated: Date()
        )
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), data: loadWidgetData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        let data = loadWidgetData()
        let entry = SimpleEntry(date: currentDate, data: data)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadWidgetData() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: "group.com.ronnie.dmflow"),
              let data = defaults.data(forKey: "widgetData"),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .empty
        }
        return widgetData
    }
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text("DMFlow")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()

            if data.overdueCount > 0 {
                CountRow(
                    icon: "exclamationmark.circle.fill",
                    color: .red,
                    count: data.overdueCount,
                    label: "Overdue"
                )
            }

            if data.todayCount > 0 {
                CountRow(
                    icon: "clock.fill",
                    color: .orange,
                    count: data.todayCount,
                    label: "Today"
                )
            }

            if data.hotLeadCount > 0 {
                CountRow(
                    icon: "flame.fill",
                    color: .orange,
                    count: data.hotLeadCount,
                    label: "Hot"
                )
            }

            if data.overdueCount == 0 && data.todayCount == 0 && data.hotLeadCount == 0 {
                Text("All caught up!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct CountRow: View {
    let icon: String
    let color: Color
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text("\(count)")
                .fontWeight(.semibold)
            Text(label)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let data: WidgetData

    var body: some View {
        HStack(spacing: 16) {
            // Left side - counts
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                    Text("DMFlow")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Spacer()

                HStack(spacing: 16) {
                    VStack {
                        Text("\(data.overdueCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(data.overdueCount > 0 ? .red : .secondary)
                        Text("Overdue")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack {
                        Text("\(data.todayCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(data.todayCount > 0 ? .orange : .secondary)
                        Text("Today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack {
                        Text("\(data.hotLeadCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(data.hotLeadCount > 0 ? .orange : .secondary)
                        Text("Hot")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Right side - next prospect
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if let prospect = data.upcomingProspects.first {
                    HStack {
                        if prospect.isHotLead {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                        Text(prospect.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }

                    if let handle = prospect.handle, !handle.isEmpty {
                        Text("@\(handle)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack {
                        Image(systemName: platformIcon(for: prospect.platform))
                            .font(.caption2)
                        Text(platformName(for: prospect.platform))
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Text("No follow-ups")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
    }

    private func platformIcon(for platform: String) -> String {
        switch platform {
        case "instagram": return "camera.fill"
        case "facebook": return "person.2.fill"
        case "sms": return "message.fill"
        case "whatsapp": return "phone.fill"
        default: return "ellipsis.circle.fill"
        }
    }

    private func platformName(for platform: String) -> String {
        switch platform {
        case "instagram": return "Instagram"
        case "facebook": return "Facebook"
        case "sms": return "SMS"
        case "whatsapp": return "WhatsApp"
        default: return "Other"
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text("DMFlow")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                HStack(spacing: 12) {
                    StatBadge(count: data.overdueCount, label: "Overdue", color: .red)
                    StatBadge(count: data.todayCount, label: "Today", color: .orange)
                }
            }

            Divider()

            // Follow-up list
            Text("Today's Follow-Ups")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if data.upcomingProspects.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("All caught up!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(data.upcomingProspects.prefix(5)) { prospect in
                        ProspectRow(prospect: prospect)
                    }

                    if data.upcomingProspects.count > 5 {
                        Text("+\(data.upcomingProspects.count - 5) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Text("\(data.totalCount) total prospects")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Tap to open")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
    }
}

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .fontWeight(.bold)
            Text(label)
        }
        .font(.caption)
        .foregroundStyle(count > 0 ? color : .secondary)
    }
}

struct ProspectRow: View {
    let prospect: WidgetProspect

    var body: some View {
        HStack {
            if prospect.isHotLead {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(prospect.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let handle = prospect.handle, !handle.isEmpty {
                    Text("@\(handle)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: platformIcon(for: prospect.platform))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func platformIcon(for platform: String) -> String {
        switch platform {
        case "instagram": return "camera.fill"
        case "facebook": return "person.2.fill"
        case "sms": return "message.fill"
        case "whatsapp": return "phone.fill"
        default: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Widget Entry View

struct DMFlowWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Widget Configuration

struct DMFlowWidget: Widget {
    let kind: String = "DMFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DMFlowWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("DMFlow")
        .description("Track your prospect follow-ups at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    DMFlowWidget()
} timeline: {
    SimpleEntry(date: .now, data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    DMFlowWidget()
} timeline: {
    SimpleEntry(date: .now, data: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    DMFlowWidget()
} timeline: {
    SimpleEntry(date: .now, data: .placeholder)
}
