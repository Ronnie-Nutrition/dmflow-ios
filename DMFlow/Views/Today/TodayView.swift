//
//  TodayView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProspects: [Prospect]
    @StateObject private var cloudKitService = CloudKitService.shared
    @State private var showingAddProspect = false
    @State private var showingPowerHour = false

    private var overdueProspects: [Prospect] {
        allProspects.filter { $0.isOverdue && $0.stage != .client && $0.stage != .dnd }
            .sorted { ($0.nextFollowUp ?? Date()) < ($1.nextFollowUp ?? Date()) }
    }

    private var todayProspects: [Prospect] {
        allProspects.filter { $0.isDueToday && $0.stage != .client && $0.stage != .dnd }
            .sorted { $0.name < $1.name }
    }

    private var hotLeads: [Prospect] {
        allProspects.filter { $0.isHotLead && $0.stage != .client && $0.stage != .dnd }
            .sorted { $0.lastContact > $1.lastContact }
    }

    private var recentActivity: [Prospect] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return allProspects.filter { $0.lastContact >= yesterday }
            .sorted { $0.lastContact > $1.lastContact }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection

                    if !overdueProspects.isEmpty {
                        ProspectSection(
                            title: "Overdue",
                            icon: "exclamationmark.circle.fill",
                            color: AppColors.danger,
                            prospects: overdueProspects
                        )
                    }

                    if !todayProspects.isEmpty {
                        ProspectSection(
                            title: "Today",
                            icon: "clock.fill",
                            color: AppColors.warning,
                            prospects: todayProspects
                        )
                    }

                    if !hotLeads.isEmpty {
                        ProspectSection(
                            title: "Hot Leads",
                            icon: "flame.fill",
                            color: .orange,
                            prospects: hotLeads
                        )
                    }

                    if !recentActivity.isEmpty {
                        ProspectSection(
                            title: "Recent Activity",
                            icon: "clock.arrow.circlepath",
                            color: AppColors.primary,
                            prospects: recentActivity
                        )
                    }

                    if overdueProspects.isEmpty && todayProspects.isEmpty && hotLeads.isEmpty && recentActivity.isEmpty {
                        emptyStateView
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingPowerHour = true
                    } label: {
                        Label("Power Hour", systemImage: "bolt.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline)
                    }
                    .disabled(overdueProspects.isEmpty && todayProspects.isEmpty && hotLeads.isEmpty)
                }

                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        SyncStatusButton(cloudKitService: cloudKitService)
                        Button {
                            showingAddProspect = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddProspect) {
                AddProspectView()
            }
            .fullScreenCover(isPresented: $showingPowerHour) {
                PowerHourView()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Date(), format: .dateTime.weekday(.wide).month().day())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                StatCard(
                    title: "Overdue",
                    count: overdueProspects.count,
                    color: AppColors.danger
                )
                StatCard(
                    title: "Today",
                    count: todayProspects.count,
                    color: AppColors.warning
                )
                StatCard(
                    title: "Hot",
                    count: hotLeads.count,
                    color: .orange
                )
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.success)

            Text("All caught up!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No follow-ups due today. Add a new prospect to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddProspect = true
            } label: {
                Label("Add Prospect", systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding(40)
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(count > 0 ? color : .secondary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct SyncStatusButton: View {
    @ObservedObject var cloudKitService: CloudKitService

    var body: some View {
        Button {
            Task {
                await cloudKitService.triggerSync()
            }
        } label: {
            Image(systemName: cloudKitService.syncStatus.icon)
                .font(.title3)
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, isActive: cloudKitService.syncStatus == .syncing)
        }
        .disabled(cloudKitService.syncStatus == .syncing || cloudKitService.accountStatus != .available)
        .accessibilityLabel("iCloud Sync: \(cloudKitService.syncStatus.displayText)")
    }

    private var statusColor: Color {
        switch cloudKitService.syncStatus {
        case .synced: return .green
        case .syncing: return .blue
        case .error: return .red
        case .offline: return .orange
        case .notSignedIn, .idle: return .secondary
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
