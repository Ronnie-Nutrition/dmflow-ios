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
    let prefillPlatform: SharePlatform?
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var handle: String = ""
    @State private var platform: SharePlatform = .instagram
    @State private var stage: ShareFunnelStage = .new
    @State private var notes: String = ""
    @State private var isHotLead: Bool = false

    // Free tier limit
    private let freeProspectLimit = 15

    // Haptic feedback generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()

    private var isAtLimit: Bool {
        let defaults = UserDefaults(suiteName: "group.com.ronnie.dmflow")
        let isPro = defaults?.bool(forKey: "isPro") ?? false
        if isPro { return false }

        let currentCount = defaults?.integer(forKey: "prospectCount") ?? 0
        let pendingCount = (defaults?.array(forKey: "pendingProspects") as? [[String: Any]])?.count ?? 0
        return (currentCount + pendingCount) >= freeProspectLimit
    }

    var body: some View {
        NavigationStack {
            Form {
                if isAtLimit {
                    limitReachedSection
                }

                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("@handle", text: $handle)
                        .autocapitalization(.none)

                    Toggle(isOn: $isHotLead) {
                        Label("Hot Lead", systemImage: "flame.fill")
                    }
                    .tint(.orange)
                    .onChange(of: isHotLead) { _, _ in
                        impactLight.impactOccurred()
                    }
                }

                Section("Platform") {
                    Picker("Platform", selection: $platform) {
                        ForEach(SharePlatform.allCases, id: \.self) { platform in
                            Text(platform.displayName).tag(platform)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: platform) { _, _ in
                        selectionFeedback.selectionChanged()
                    }
                }

                Section("Stage") {
                    Picker("Stage", selection: $stage) {
                        ForEach(ShareFunnelStage.allCases, id: \.self) { stage in
                            Text(stage.displayName).tag(stage)
                        }
                    }
                    .onChange(of: stage) { _, _ in
                        selectionFeedback.selectionChanged()
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
                    Button("Cancel") {
                        impactLight.impactOccurred()
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProspect()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || isAtLimit)
                }
            }
            .onAppear {
                // Prepare haptic generators
                impactLight.prepare()
                impactMedium.prepare()
                notificationFeedback.prepare()
                selectionFeedback.prepare()

                // Apply prefilled values
                if let prefillName = prefillName {
                    name = prefillName
                }
                if let prefillHandle = prefillHandle {
                    handle = prefillHandle
                }
                if let prefillPlatform = prefillPlatform {
                    platform = prefillPlatform
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

                Text("You've reached the \(freeProspectLimit)-prospect limit. Open DMFlow and upgrade to Pro for unlimited prospects.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
        }
    }

    private func saveProspect() {
        // Provide haptic feedback for save action
        notificationFeedback.notificationOccurred(.success)

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
        prefillPlatform: .instagram,
        onSave: {},
        onCancel: {}
    )
}
