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

    @State private var name = ""
    @State private var handle = ""
    @State private var platform: Platform = .instagram
    @State private var stage: FunnelStage = .new
    @State private var notes = ""
    @State private var hasFollowUp = false
    @State private var followUpDate = Date().addingTimeInterval(86400)
    @State private var isHotLead = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
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
                        saveProspect()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
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
        dismiss()
    }
}

#Preview {
    AddProspectView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
