//
//  AddActivityView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let prospect: Prospect

    @State private var selectedType: ActivityType = .message
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(ActivityType.loggableTypes) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Log Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActivity()
                    }
                }
            }
        }
    }

    private func saveActivity() {
        let activity = ProspectActivity(
            prospectId: prospect.id,
            activityType: selectedType,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(activity)

        // Also update last contact when logging communication activities
        if selectedType == .message || selectedType == .call || selectedType == .meeting {
            prospect.markContacted()
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        dismiss()
    }
}

#Preview {
    AddActivityView(prospect: Prospect(name: "John Smith"))
        .modelContainer(for: [Prospect.self, ProspectActivity.self], inMemory: true)
}
