//
//  ContentView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allProspects: [Prospect]
    @State private var selectedTab: Tab = .today
    @State private var showingImportAlert = false
    @State private var importedCount = 0

    enum Tab: String, CaseIterable {
        case today = "Today"
        case pipeline = "Pipeline"
        case search = "Search"
        case stats = "Stats"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .today: return "clock.fill"
            case .pipeline: return "square.stack.3d.up.fill"
            case .search: return "magnifyingglass"
            case .stats: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(Tab.today.rawValue, systemImage: Tab.today.icon)
                }
                .tag(Tab.today)

            PipelineView()
                .tabItem {
                    Label(Tab.pipeline.rawValue, systemImage: Tab.pipeline.icon)
                }
                .tag(Tab.pipeline)

            SearchView()
                .tabItem {
                    Label(Tab.search.rawValue, systemImage: Tab.search.icon)
                }
                .tag(Tab.search)

            StatsView()
                .tabItem {
                    Label(Tab.stats.rawValue, systemImage: Tab.stats.icon)
                }
                .tag(Tab.stats)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(AppColors.primary)
        .onAppear {
            importPendingProspects()
            syncUsageData()
            updateNotifications()
            updateWidget()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                importPendingProspects()
                syncUsageData()
                updateNotifications()
                updateWidget()
            }
        }
        .onChange(of: allProspects.count) { _, _ in
            syncUsageData()
            updateNotifications()
            updateWidget()
        }
        .alert("Prospects Imported", isPresented: $showingImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(importedCount) prospect\(importedCount == 1 ? "" : "s") added from Share Extension")
        }
    }

    private func importPendingProspects() {
        guard let defaults = UserDefaults(suiteName: "group.com.ronnie.dmflow") else { return }

        guard let pendingProspects = defaults.array(forKey: "pendingProspects") as? [[String: Any]],
              !pendingProspects.isEmpty else { return }

        var count = 0

        for prospectData in pendingProspects {
            guard let name = prospectData["name"] as? String,
                  !name.isEmpty else { continue }

            let platformString = prospectData["platform"] as? String ?? "other"
            let stageString = prospectData["stage"] as? String ?? "new"

            let platform = Platform(rawValue: platformString) ?? .other
            let stage = FunnelStage(rawValue: stageString) ?? .new

            let handle = prospectData["handle"] as? String
            let notes = prospectData["notes"] as? String
            let isHotLead = prospectData["isHotLead"] as? Bool ?? false

            let prospect = Prospect(
                name: name,
                handle: (handle?.isEmpty ?? true) ? nil : handle,
                platform: platform,
                stage: stage,
                notes: (notes?.isEmpty ?? true) ? nil : notes,
                isHotLead: isHotLead
            )

            modelContext.insert(prospect)
            count += 1
        }

        if count > 0 {
            // Clear pending prospects after import
            defaults.removeObject(forKey: "pendingProspects")
            defaults.synchronize()

            importedCount = count
            showingImportAlert = true
            syncUsageData()
        }
    }

    private func syncUsageData() {
        UsageTracker.shared.syncToSharedDefaults(prospectCount: allProspects.count)
    }

    private func updateNotifications() {
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        guard notificationsEnabled else {
            NotificationService.shared.clearBadge()
            return
        }

        // Update badge count with overdue + today count
        let overdueCount = allProspects.filter { $0.isOverdue }.count
        let todayCount = allProspects.filter { $0.isDueToday }.count
        let badgeCount = overdueCount + todayCount
        NotificationService.shared.updateBadgeCount(badgeCount)

        // Update morning reminder with current counts
        let morningReminderTime = UserDefaults.standard.integer(forKey: "morningReminderTime")
        let hour = morningReminderTime > 0 ? morningReminderTime : 9 // Default to 9 AM
        NotificationService.shared.scheduleMorningReminder(
            hour: hour,
            overdueCount: overdueCount,
            todayCount: todayCount
        )
    }

    private func updateWidget() {
        WidgetService.shared.updateWidget(with: allProspects)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
