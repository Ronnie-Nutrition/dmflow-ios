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
    @State private var showingExportSheet = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
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
        }
    }

    private var accountSection: some View {
        Section {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(AppColors.primary)

                VStack(alignment: .leading) {
                    Text("Sign in with Apple")
                        .font(.headline)
                    Text("Sync across devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Sign In") {
                    // Sign in with Apple implementation
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Account")
        } footer: {
            Text("Sign in to sync your prospects across all your Apple devices.")
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
                showingExportSheet = true
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }

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
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://dmflow.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            Link(destination: URL(string: "https://dmflow.app/support")!) {
                Label("Support", systemImage: "questionmark.circle")
            }

            Link(destination: URL(string: "https://dmflow.app/feedback")!) {
                Label("Send Feedback", systemImage: "envelope")
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

    private func deleteAllData() {
        for prospect in allProspects {
            modelContext.delete(prospect)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
