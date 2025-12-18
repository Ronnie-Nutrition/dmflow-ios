//
//  ProspectDetailView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct ProspectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var prospect: Prospect
    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false
    @State private var suggestedMessage: String?
    @State private var isGeneratingMessage = false
    @State private var showingPaywall = false
    @State private var aiError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                stageSection
                detailsSection
                notesSection
                aiSection
                actionsSection
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle(prospect.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation {
                        isEditing.toggle()
                    }
                }
            }
        }
        .alert("Delete Prospect", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProspect()
            }
        } message: {
            Text("Are you sure you want to delete \(prospect.name)? This cannot be undone.")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .alert("AI Error", isPresented: .init(
            get: { aiError != nil },
            set: { if !$0 { aiError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(aiError ?? "")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(prospect.platform.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: prospect.platform.icon)
                    .font(.largeTitle)
                    .foregroundStyle(prospect.platform.color)
            }

            VStack(spacing: 4) {
                HStack {
                    Text(prospect.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if prospect.isHotLead {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                }

                if let handle = prospect.handle, !handle.isEmpty {
                    Text("@\(handle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(prospect.platform.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(prospect.platform.color.opacity(0.1))
                    .foregroundStyle(prospect.platform.color)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var stageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Funnel Stage")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FunnelStage.allCases) { stage in
                        StageButton(
                            stage: stage,
                            isSelected: prospect.stage == stage,
                            isEnabled: isEditing
                        ) {
                            withAnimation {
                                prospect.stage = stage
                                prospect.updatedAt = Date()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var detailsSection: some View {
        VStack(spacing: 16) {
            if isEditing {
                editableDetails
            } else {
                readOnlyDetails
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var readOnlyDetails: some View {
        VStack(spacing: 12) {
            DetailRow(
                icon: "clock",
                title: "Last Contact",
                value: prospect.lastContact.formatted(date: .abbreviated, time: .omitted)
            )

            if let followUp = prospect.nextFollowUp {
                DetailRow(
                    icon: "calendar",
                    title: "Next Follow-Up",
                    value: followUp.formatted(date: .abbreviated, time: .omitted),
                    valueColor: prospect.isOverdue ? AppColors.danger : nil
                )
            }

            DetailRow(
                icon: "calendar.badge.plus",
                title: "Added",
                value: prospect.createdAt.formatted(date: .abbreviated, time: .omitted)
            )

            DetailRow(
                icon: "flame",
                title: "Hot Lead",
                value: prospect.isHotLead ? "Yes" : "No",
                valueColor: prospect.isHotLead ? .orange : nil
            )
        }
    }

    private var editableDetails: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Name", text: $prospect.name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Handle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("@handle", text: Binding(
                    get: { prospect.handle ?? "" },
                    set: { prospect.handle = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Platform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Platform", selection: $prospect.platform) {
                    ForEach(Platform.allCases) { platform in
                        Label(platform.displayName, systemImage: platform.icon)
                            .tag(platform)
                    }
                }
                .pickerStyle(.menu)
            }

            DatePicker(
                "Next Follow-Up",
                selection: Binding(
                    get: { prospect.nextFollowUp ?? Date() },
                    set: { prospect.nextFollowUp = $0 }
                ),
                displayedComponents: .date
            )

            Toggle("Hot Lead", isOn: $prospect.isHotLead)
                .tint(.orange)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)

            if isEditing {
                TextEditor(text: Binding(
                    get: { prospect.notes ?? "" },
                    set: { prospect.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(prospect.notes ?? "No notes")
                    .font(.body)
                    .foregroundStyle(prospect.notes == nil ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Message Suggestion", systemImage: "sparkles")
                    .font(.headline)

                Spacer()

                if !UsageTracker.shared.isPro {
                    Text("PRO")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            if let message = suggestedMessage {
                VStack(alignment: .leading, spacing: 12) {
                    Text(message)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack {
                        Button {
                            UIPasteboard.general.string = message
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button {
                            suggestedMessage = nil
                        } label: {
                            Label("Clear", systemImage: "xmark")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Spacer()

                        Button {
                            generateMessage()
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isGeneratingMessage)
                    }
                }
            } else {
                Button {
                    generateMessage()
                } label: {
                    HStack {
                        if isGeneratingMessage {
                            ProgressView()
                                .controlSize(.small)
                            Text("Generating...")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Suggest Follow-Up Message")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGeneratingMessage)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                prospect.markContacted()
            } label: {
                Label("Mark as Contacted", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Prospect", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func generateMessage() {
        guard UsageTracker.shared.canUseAI else {
            showingPaywall = true
            return
        }

        isGeneratingMessage = true

        Task {
            do {
                let message = try await AIService.shared.generateFollowUpMessage(for: prospect)
                await MainActor.run {
                    suggestedMessage = message
                    isGeneratingMessage = false
                }
            } catch let error as AIError {
                await MainActor.run {
                    isGeneratingMessage = false
                    if case .proRequired = error {
                        showingPaywall = true
                    } else {
                        aiError = error.localizedDescription
                    }
                }
            } catch {
                await MainActor.run {
                    isGeneratingMessage = false
                    aiError = error.localizedDescription
                }
            }
        }
    }

    private func deleteProspect() {
        modelContext.delete(prospect)
        dismiss()
    }
}

struct StageButton: View {
    let stage: FunnelStage
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: stage.icon)
                    .font(.title3)
                Text(stage.displayName)
                    .font(.caption2)
            }
            .frame(width: 70, height: 60)
            .background(isSelected ? stage.color : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!isEnabled && !isSelected)
        .opacity(isEnabled || isSelected ? 1 : 0.5)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor ?? .primary)
        }
    }
}

#Preview {
    NavigationStack {
        ProspectDetailView(prospect: Prospect(
            name: "John Smith",
            handle: "johnsmith",
            platform: .instagram,
            stage: .engaged,
            isHotLead: true
        ))
    }
    .modelContainer(for: Prospect.self, inMemory: true)
}
