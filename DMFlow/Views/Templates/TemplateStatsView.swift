//
//  TemplateStatsView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct TemplateStatsView: View {
    @Query(sort: \MessageTemplate.name) private var allTemplates: [MessageTemplate]
    @State private var selectedCategory: TemplateCategory?
    @State private var sortBy: SortOption = .conversionRate

    enum SortOption: String, CaseIterable {
        case conversionRate = "Conversion Rate"
        case timesSent = "Times Sent"
        case name = "Name"
    }

    private var filteredTemplates: [MessageTemplate] {
        var templates = allTemplates

        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }

        switch sortBy {
        case .conversionRate:
            templates.sort { $0.conversionRate > $1.conversionRate }
        case .timesSent:
            templates.sort { $0.timesSent > $1.timesSent }
        case .name:
            templates.sort { $0.name < $1.name }
        }

        return templates
    }

    private var templatesWithData: [MessageTemplate] {
        filteredTemplates.filter { $0.timesSent > 0 }
    }

    private var abTestGroups: [UUID: [MessageTemplate]] {
        let variants = allTemplates.filter { $0.variantGroup != nil }
        return Dictionary(grouping: variants) { $0.variantGroup! }
    }

    var body: some View {
        List {
            // Summary Section
            Section {
                HStack {
                    TemplateStatBox(
                        title: "Total Sends",
                        value: "\(allTemplates.reduce(0) { $0 + $1.timesSent })",
                        icon: "paperplane.fill",
                        color: AppColors.primary
                    )

                    TemplateStatBox(
                        title: "Conversions",
                        value: "\(allTemplates.reduce(0) { $0 + $1.timesConverted })",
                        icon: "checkmark.circle.fill",
                        color: AppColors.success
                    )

                    TemplateStatBox(
                        title: "Avg Rate",
                        value: averageConversionRate,
                        icon: "percent",
                        color: .orange
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // A/B Tests Section
            if !abTestGroups.isEmpty {
                Section("A/B Tests") {
                    ForEach(Array(abTestGroups.keys), id: \.self) { groupId in
                        if let variants = abTestGroups[groupId], variants.count > 1 {
                            ABTestComparisonRow(variants: variants)
                        }
                    }
                }
            }

            // Filter & Sort Controls
            Section {
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(nil as TemplateCategory?)
                    ForEach(TemplateCategory.allCases) { category in
                        Text(category.rawValue).tag(category as TemplateCategory?)
                    }
                }

                Picker("Sort By", selection: $sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            // Templates Performance
            Section("Template Performance") {
                if templatesWithData.isEmpty {
                    ContentUnavailableView {
                        Label("No Data Yet", systemImage: "chart.bar")
                    } description: {
                        Text("Use templates with prospects to see performance stats")
                    }
                } else {
                    ForEach(templatesWithData) { template in
                        TemplateStatsRow(template: template)
                    }
                }
            }
        }
        .navigationTitle("Template Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var averageConversionRate: String {
        let templatesWithSends = allTemplates.filter { $0.timesSent > 0 }
        guard !templatesWithSends.isEmpty else { return "0%" }

        let totalSent = templatesWithSends.reduce(0) { $0 + $1.timesSent }
        let totalConverted = templatesWithSends.reduce(0) { $0 + $1.timesConverted }

        guard totalSent > 0 else { return "0%" }
        let rate = Double(totalConverted) / Double(totalSent) * 100
        return String(format: "%.1f%%", rate)
    }
}

struct TemplateStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TemplateStatsRow: View {
    let template: MessageTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.displayName)
                    .font(.headline)

                if template.isVariant {
                    Text("A/B")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.primary)
                        .clipShape(Capsule())
                }

                Spacer()

                ConversionRateBadge(rate: template.conversionRate)
            }

            HStack(spacing: 16) {
                Label("\(template.timesSent) sent", systemImage: "paperplane")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label("\(template.timesConverted) converted", systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(template.category.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

struct ConversionRateBadge: View {
    let rate: Double

    private var color: Color {
        if rate >= 50 { return AppColors.success }
        if rate >= 25 { return .orange }
        if rate > 0 { return AppColors.warning }
        return .secondary
    }

    var body: some View {
        Text(String(format: "%.1f%%", rate))
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

struct ABTestComparisonRow: View {
    let variants: [MessageTemplate]

    private var sortedVariants: [MessageTemplate] {
        variants.sorted { ($0.variantLetter ?? "") < ($1.variantLetter ?? "") }
    }

    private var winner: MessageTemplate? {
        let withData = variants.filter { $0.timesSent >= 5 }
        return withData.max(by: { $0.conversionRate < $1.conversionRate })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(variants.first?.name ?? "A/B Test")
                    .font(.headline)

                Spacer()

                if let winner = winner {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text(winner.variantLetter ?? "?")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                }
            }

            HStack(spacing: 12) {
                ForEach(sortedVariants) { variant in
                    VStack(spacing: 4) {
                        Text(variant.variantLetter ?? "?")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(variant.id == winner?.id ? AppColors.success : .primary)

                        Text(String(format: "%.1f%%", variant.conversionRate))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("\(variant.timesSent) sent")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(variant.id == winner?.id ? AppColors.success.opacity(0.1) : Color(.systemGray6))
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        TemplateStatsView()
    }
    .modelContainer(for: [Prospect.self, MessageTemplate.self], inMemory: true)
}
