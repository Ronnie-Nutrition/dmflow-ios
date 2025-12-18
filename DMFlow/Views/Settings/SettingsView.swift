//
//  SettingsView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProspects: [Prospect]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("morningReminderTime") private var morningReminderTime = 9
    @State private var showingDeleteConfirmation = false
    @State private var exportFile: ExportFile?

    var body: some View {
        NavigationStack {
            List {
                notificationsSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Are you sure you want to delete all \(allProspects.count) prospects? This action cannot be undone.")
            }
            .sheet(item: $exportFile) { file in
                ShareSheet(items: [file.url])
            }
        }
    }


    private var notificationsSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)

            if notificationsEnabled {
                Picker("Morning Reminder", selection: $morningReminderTime) {
                    ForEach(6...12, id: \.self) { hour in
                        Text("\(hour):00 AM").tag(hour)
                    }
                }

                HStack {
                    Text("Follow-up Reminders")
                    Spacer()
                    Text("Enabled")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Get reminded about overdue follow-ups and daily summaries.")
        }
    }

    private var dataSection: some View {
        Section {
            HStack {
                Text("Total Prospects")
                Spacer()
                Text("\(allProspects.count)")
                    .foregroundStyle(.secondary)
            }

            Button {
                exportData()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            .disabled(allProspects.isEmpty)

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
            }
        } header: {
            Text("Data Management")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            if let privacyURL = URL(string: "https://ronnie-nutrition.github.io/dmflow-ios/privacy/") {
                Link(destination: privacyURL) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }

            if let supportURL = URL(string: "https://ronnie-nutrition.github.io/dmflow-ios/support/") {
                Link(destination: supportURL) {
                    Label("Support", systemImage: "questionmark.circle")
                }
            }

            if let feedbackURL = URL(string: "https://ronnie-nutrition.github.io/dmflow-ios/support/") {
                Link(destination: feedbackURL) {
                    Label("Send Feedback", systemImage: "envelope")
                }
            }
        } header: {
            Text("About")
        } footer: {
            Text("DMFlow - DM Prospect Tracker\nBuilt for network marketers")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func deleteAllData() {
        for prospect in allProspects {
            modelContext.delete(prospect)
        }
    }

    private func exportData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        var csv = "Name,Handle,Platform,Stage,Last Contact,Next Follow-Up,Hot Lead,Notes,Created\n"

        for prospect in allProspects {
            let name = escapeCsvField(prospect.name)
            let handle = escapeCsvField(prospect.handle ?? "")
            let platform = prospect.platform.displayName
            let stage = prospect.stage.displayName
            let lastContact = dateFormatter.string(from: prospect.lastContact)
            let nextFollowUp = prospect.nextFollowUp.map { dateFormatter.string(from: $0) } ?? ""
            let isHotLead = prospect.isHotLead ? "Yes" : "No"
            let notes = escapeCsvField(prospect.notes ?? "")
            let created = dateFormatter.string(from: prospect.createdAt)

            csv += "\(name),\(handle),\(platform),\(stage),\(lastContact),\(nextFollowUp),\(isHotLead),\(notes),\(created)\n"
        }

        let fileName = "DMFlow_Export_\(dateFormatter.string(from: Date()).replacingOccurrences(of: "/", with: "-")).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            exportFile = ExportFile(url: tempURL)
        } catch {
            print("Export failed: \(error)")
        }
    }

    private func escapeCsvField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}

struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
