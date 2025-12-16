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
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
