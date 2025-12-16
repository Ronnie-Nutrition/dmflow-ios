//
//  ShareExtensionView.swift
//  DMFlowShare
//
//  Created by Ronnie Craig
//

import SwiftUI

struct ShareExtensionView: View {
    let prefillName: String?
    let prefillHandle: String?
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var handle: String = ""
    @State private var platform: SharePlatform = .instagram
    @State private var stage: ShareFunnelStage = .new
    @State private var notes: String = ""
    @State private var isHotLead: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("@handle", text: $handle)
                        .autocapitalization(.none)

                    Toggle(isOn: $isHotLead) {
                        Label("Hot Lead", systemImage: "flame.fill")
                    }
                    .tint(.orange)
                }

                Section("Platform") {
                    Picker("Platform", selection: $platform) {
                        ForEach(SharePlatform.allCases, id: \.self) { platform in
                            Text(platform.displayName).tag(platform)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Stage") {
                    Picker("Stage", selection: $stage) {
                        ForEach(ShareFunnelStage.allCases, id: \.self) { stage in
                            Text(stage.displayName).tag(stage)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Quick notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Prospect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProspect()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let prefillName = prefillName {
                    name = prefillName
                }
                if let prefillHandle = prefillHandle {
                    handle = prefillHandle
                }
            }
        }
    }

    private func saveProspect() {
        // Save to shared UserDefaults (App Group)
        let defaults = UserDefaults(suiteName: "group.com.ronnie.dmflow")

        var pendingProspects = defaults?.array(forKey: "pendingProspects") as? [[String: Any]] ?? []

        let prospect: [String: Any] = [
            "id": UUID().uuidString,
            "name": name,
            "handle": handle.isEmpty ? NSNull() : handle,
            "platform": platform.rawValue,
            "stage": stage.rawValue,
            "notes": notes.isEmpty ? NSNull() : notes,
            "isHotLead": isHotLead,
            "createdAt": Date().timeIntervalSince1970
        ]

        pendingProspects.append(prospect)
        defaults?.set(pendingProspects, forKey: "pendingProspects")
        defaults?.synchronize()

        onSave()
    }
}

// Duplicated enums for Share Extension (to avoid module dependencies)
enum SharePlatform: String, CaseIterable {
    case instagram, facebook, sms, whatsapp, other

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        case .sms: return "SMS"
        case .whatsapp: return "WhatsApp"
        case .other: return "Other"
        }
    }
}

enum ShareFunnelStage: String, CaseIterable {
    case new, engaged, presented, followUp

    var displayName: String {
        switch self {
        case .new: return "New"
        case .engaged: return "Engaged"
        case .presented: return "Presented"
        case .followUp: return "Follow-Up"
        }
    }
}

#Preview {
    ShareExtensionView(
        prefillName: nil,
        prefillHandle: "johnsmith",
        onSave: {},
        onCancel: {}
    )
}
