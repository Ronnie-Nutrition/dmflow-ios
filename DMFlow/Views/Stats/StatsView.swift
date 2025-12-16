//
//  StatsView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProspects: [Prospect]
    @State private var selectedPeriod: StatsPeriod = .week

    enum StatsPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }

    private var filteredProspects: [Prospect] {
        guard selectedPeriod != .all else { return Array(allProspects) }

        let startDate: Date
        let calendar = Calendar.current

        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .all:
            return Array(allProspects)
        }

        return allProspects.filter { $0.createdAt >= startDate }
    }

    private var stageData: [(FunnelStage, Int)] {
        FunnelStage.allCases.map { stage in
            (stage, allProspects.filter { $0.stage == stage }.count)
        }
    }

    private var conversionRate: Double {
        let total = allProspects.count
        guard total > 0 else { return 0 }
        let clients = allProspects.filter { $0.stage == .client }.count
        return Double(clients) / Double(total) * 100
    }

    private var followUpCompliance: Double {
        let withFollowUp = allProspects.filter { $0.nextFollowUp != nil }
        guard !withFollowUp.isEmpty else { return 100 }
        let completed = withFollowUp.filter { !$0.isOverdue }.count
        return Double(completed) / Double(withFollowUp.count) * 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker

                    overviewCards

                    pipelineChart

                    metricsSection
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Stats")
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var overviewCards: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Total",
                value: "\(allProspects.count)",
                icon: "person.3.fill",
                color: AppColors.primary
            )

            MetricCard(
                title: "Conversion",
                value: String(format: "%.0f%%", conversionRate),
                icon: "chart.line.uptrend.xyaxis",
                color: AppColors.success
            )

            MetricCard(
                title: "Follow-Up",
                value: String(format: "%.0f%%", followUpCompliance),
                icon: "clock.badge.checkmark.fill",
                color: AppColors.warning
            )
        }
    }

    private var pipelineChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pipeline Overview")
                .font(.headline)

            Chart {
                ForEach(stageData, id: \.0) { stage, count in
                    BarMark(
                        x: .value("Stage", stage.displayName),
                        y: .value("Count", count)
                    )
                    .foregroundStyle(stage.color)
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Metrics")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(FunnelStage.allCases) { stage in
                    let count = allProspects.filter { $0.stage == stage }.count
                    let avgDays = averageDaysInStage(stage)

                    MetricRow(
                        stage: stage,
                        count: count,
                        avgDays: avgDays
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func averageDaysInStage(_ stage: FunnelStage) -> Int {
        let prospectsInStage = allProspects.filter { $0.stage == stage }
        guard !prospectsInStage.isEmpty else { return 0 }

        let totalDays = prospectsInStage.reduce(0) { $0 + $1.daysInCurrentStage }
        return totalDays / prospectsInStage.count
    }
}

struct MetricCard: View {
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
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct MetricRow: View {
    let stage: FunnelStage
    let count: Int
    let avgDays: Int

    var body: some View {
        HStack {
            Image(systemName: stage.icon)
                .foregroundStyle(stage.color)
                .frame(width: 24)

            Text(stage.displayName)
                .font(.subheadline)

            Spacer()

            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(stage.color)
                .frame(width: 40, alignment: .trailing)

            Text("~\(avgDays)d")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
