//
//  SearchView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProspects: [Prospect]
    @State private var searchText = ""
    @State private var selectedStage: FunnelStage?
    @State private var selectedPlatform: Platform?
    @State private var showHotLeadsOnly = false
    @State private var showFilters = false

    private var filteredProspects: [Prospect] {
        var results = allProspects

        if !searchText.isEmpty {
            results = results.filter { prospect in
                prospect.name.localizedCaseInsensitiveContains(searchText) ||
                (prospect.handle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (prospect.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        if let stage = selectedStage {
            results = results.filter { $0.stage == stage }
        }

        if let platform = selectedPlatform {
            results = results.filter { $0.platform == platform }
        }

        if showHotLeadsOnly {
            results = results.filter { $0.isHotLead }
        }

        return results.sorted { $0.name < $1.name }
    }

    private var hasActiveFilters: Bool {
        selectedStage != nil || selectedPlatform != nil || showHotLeadsOnly
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showFilters {
                    filterSection
                }

                List {
                    ForEach(filteredProspects) { prospect in
                        NavigationLink {
                            ProspectDetailView(prospect: prospect)
                        } label: {
                            ProspectRow(prospect: prospect)
                        }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if filteredProspects.isEmpty {
                        emptyStateView
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search by name or handle")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            showFilters.toggle()
                        }
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? AppColors.primary : .primary)
                    }
                }
            }
        }
    }

    private var filterSection: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "Stage",
                        value: selectedStage?.displayName,
                        isActive: selectedStage != nil
                    ) {
                        selectedStage = nil
                    }

                    ForEach(FunnelStage.allCases) { stage in
                        FilterOption(
                            title: stage.displayName,
                            isSelected: selectedStage == stage
                        ) {
                            selectedStage = selectedStage == stage ? nil : stage
                        }
                    }
                }
                .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "Platform",
                        value: selectedPlatform?.displayName,
                        isActive: selectedPlatform != nil
                    ) {
                        selectedPlatform = nil
                    }

                    ForEach(Platform.allCases) { platform in
                        FilterOption(
                            title: platform.displayName,
                            isSelected: selectedPlatform == platform
                        ) {
                            selectedPlatform = selectedPlatform == platform ? nil : platform
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                Toggle("Hot Leads Only", isOn: $showHotLeadsOnly)
                    .toggleStyle(.switch)
                    .tint(AppColors.warning)

                Spacer()

                if hasActiveFilters {
                    Button("Clear All") {
                        withAnimation {
                            selectedStage = nil
                            selectedPlatform = nil
                            showHotLeadsOnly = false
                        }
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "magnifyingglass")
        } description: {
            if searchText.isEmpty && !hasActiveFilters {
                Text("Start typing to search your prospects")
            } else {
                Text("Try adjusting your search or filters")
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let value: String?
    let isActive: Bool
    let onClear: () -> Void

    var body: some View {
        if isActive, let value = value {
            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.primary.opacity(0.1))
            .foregroundStyle(AppColors.primary)
            .clipShape(Capsule())
        }
    }
}

struct FilterOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppColors.primary : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct ProspectRow: View {
    let prospect: Prospect

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prospect.platform.icon)
                .font(.title3)
                .foregroundStyle(prospect.platform.color)
                .frame(width: 36, height: 36)
                .background(prospect.platform.color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(prospect.name)
                        .font(.body)
                        .fontWeight(.medium)

                    if prospect.isHotLead {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if let handle = prospect.handle, !handle.isEmpty {
                    Text("@\(handle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(prospect.stage.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(prospect.stage.color)

                Text("\(prospect.daysSinceLastContact)d ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
