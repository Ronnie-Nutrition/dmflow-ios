//
//  AddProspectView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct AddProspectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allProspects: [Prospect]

    @State private var name = ""
    @State private var handle = ""
    @State private var platform: Platform = .instagram
    @State private var stage: FunnelStage = .new
    @State private var notes = ""
    @State private var hasFollowUp = false
    @State private var followUpDate = Date().addingTimeInterval(86400)
    @State private var isHotLead = false
    @State private var showingPaywall = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isAtProspectLimit: Bool {
        !UsageTracker.shared.canAddProspect(currentCount: allProspects.count)
    }

    var body: some View {
        NavigationStack {
            Form {
                if isAtProspectLimit {
                    limitReachedSection
                }
                basicInfoSection
                platformSection
                stageSection
                followUpSection
                notesSection
            }
            .navigationTitle("Add Prospect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isAtProspectLimit {
                            showingPaywall = true
                        } else {
                            saveProspect()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onChange(of: SubscriptionManager.shared.isPro) { _, isPro in
                if isPro && canSave {
                    saveProspect()
                }
            }
        }
    }

    private var limitReachedSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)

                Text("Free Limit Reached")
                    .font(.headline)

                Text("You've reached the \(UsageTracker.freeProspectLimit)-prospect limit on the free tier. Upgrade to DMFlow Pro for unlimited prospects.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showingPaywall = true
                } label: {
                    Text("Upgrade to Pro")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var basicInfoSection: some View {
        Section {
            TextField("Name", text: $name)
                .textContentType(.name)
                .autocorrectionDisabled()

            TextField("@handle (optional)", text: $handle)
                .textContentType(.username)
                .autocapitalization(.none)
                .autocorrectionDisabled()

            Toggle(isOn: $isHotLead) {
                Label("Hot Lead", systemImage: "flame.fill")
                    .foregroundStyle(isHotLead ? .orange : .primary)
            }
            .tint(.orange)
        } header: {
            Text("Basic Info")
        }
    }

    private var platformSection: some View {
        Section {
            Picker("Platform", selection: $platform) {
                ForEach(Platform.allCases) { platform in
                    Label(platform.displayName, systemImage: platform.icon)
                        .tag(platform)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Platform")
        }
    }

    private var stageSection: some View {
        Section {
            Picker("Stage", selection: $stage) {
                ForEach(FunnelStage.allCases) { stage in
                    Label(stage.displayName, systemImage: stage.icon)
                        .tag(stage)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Funnel Stage")
        } footer: {
            Text(stage.description)
        }
    }

    private var followUpSection: some View {
        Section {
            Toggle("Schedule Follow-Up", isOn: $hasFollowUp)

            if hasFollowUp {
                DatePicker(
                    "Follow-Up Date",
                    selection: $followUpDate,
                    in: Date()...,
                    displayedComponents: .date
                )
            }
        } header: {
            Text("Follow-Up")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Add notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Notes")
        }
    }

    private func saveProspect() {
        let prospect = Prospect(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            handle: handle.isEmpty ? nil : handle.trimmingCharacters(in: .whitespacesAndNewlines),
            platform: platform,
            stage: stage,
            nextFollowUp: hasFollowUp ? followUpDate : nil,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isHotLead: isHotLead
        )

        modelContext.insert(prospect)

        // Schedule notification if follow-up is set and notifications are enabled
        if hasFollowUp {
            let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
            if notificationsEnabled {
                NotificationService.shared.scheduleFollowUpReminder(for: prospect)
            }

            // Sync to calendar if enabled
            CalendarService.shared.syncFollowUp(for: prospect)
        }

        dismiss()
    }
}

#Preview {
    AddProspectView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
