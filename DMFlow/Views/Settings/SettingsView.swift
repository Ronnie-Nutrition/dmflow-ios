//
//  SettingsView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData
import EventKit
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProspects: [Prospect]
    @StateObject private var cloudKitService = CloudKitService.shared
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("morningReminderTime") private var morningReminderTime = 9
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    @State private var showingDeleteConfirmation = false
    @State private var exportFile: ExportFile?
    @State private var apiKey: String = AIService.getAPIKey()
    @State private var calendarAuthDenied = false
    @State private var showingPaywall = false

    private let usageTracker = UsageTracker.shared

    // Profile settings - initialized in onAppear
    @State private var profileName: String = ""
    @State private var profileIndustry: String = ""
    @State private var profileOffering: String = ""
    @State private var profileTone: TonePreference = .friendly
    @State private var profileEmoji: EmojiPreference = .minimal
    @State private var profileSamples: String = ""
    @State private var profileLoaded: Bool = false

    var body: some View {
        NavigationStack {
            List {
                subscriptionSection
                profileSection
                templatesSection
                notificationsSection
                calendarSection
                iCloudSection
                aiSection
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
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                loadProfile()
            }
        }
    }

    private func loadProfile() {
        guard !profileLoaded else { return }
        let profile = AIService.getUserProfile()
        profileName = profile.name
        profileIndustry = profile.industry
        profileOffering = profile.offering
        profileTone = profile.tone
        profileEmoji = profile.emojiUsage
        profileSamples = profile.sampleMessages
        profileLoaded = true
    }

    private var subscriptionSection: some View {
        Section {
            if usageTracker.isPro {
                HStack {
                    Label("DMFlow Pro", systemImage: "crown.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Text("Active")
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                }

                Button {
                    Task {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            try? await AppStore.showManageSubscriptions(in: windowScene)
                        }
                    }
                } label: {
                    Label("Manage Subscription", systemImage: "creditcard")
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upgrade to Pro")
                            .font(.headline)
                        Text("Unlock unlimited prospects, templates, AI & analytics")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.orange)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingPaywall = true
                }

                HStack {
                    Text("Prospects")
                    Spacer()
                    Text("\(allProspects.count)/\(UsageTracker.freeProspectLimit)")
                        .foregroundStyle(allProspects.count >= UsageTracker.freeProspectLimit ? .red : .secondary)
                }
                .font(.subheadline)
            }
        } header: {
            Text("Subscription")
        } footer: {
            if !usageTracker.isPro {
                Text("Free tier: \(UsageTracker.freeProspectLimit) prospects, \(UsageTracker.freeTemplateLimit) custom templates")
            }
        }
    }

    private var profileSection: some View {
        Section {
            TextField("Your Name", text: $profileName)
                .textContentType(.name)
                .onChange(of: profileName) { _, _ in saveProfile() }

            TextField("Industry/Niche", text: $profileIndustry, prompt: Text("e.g., Health & Wellness, Coaching"))
                .onChange(of: profileIndustry) { _, _ in saveProfile() }

            TextField("What You Offer", text: $profileOffering, prompt: Text("e.g., nutrition products, business coaching"))
                .onChange(of: profileOffering) { _, _ in saveProfile() }

            Picker("Communication Tone", selection: $profileTone) {
                ForEach(TonePreference.allCases) { tone in
                    Text(tone.rawValue).tag(tone)
                }
            }
            .onChange(of: profileTone) { _, _ in saveProfile() }

            Picker("Emoji Usage", selection: $profileEmoji) {
                ForEach(EmojiPreference.allCases) { emoji in
                    Text(emoji.rawValue).tag(emoji)
                }
            }
            .onChange(of: profileEmoji) { _, _ in saveProfile() }

            NavigationLink {
                SampleMessagesEditor(sampleMessages: $profileSamples, onSave: saveProfile)
            } label: {
                HStack {
                    Text("Sample Messages")
                    Spacer()
                    if profileSamples.isEmpty {
                        Text("Not set")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Configured")
                            .foregroundStyle(.green)
                    }
                }
            }
        } header: {
            Text("Your Profile")
        } footer: {
            Text("Help the AI match your voice and style by filling out your profile.")
        }
    }

    private func saveProfile() {
        guard profileLoaded else { return }
        let profile = UserProfile(
            name: profileName,
            industry: profileIndustry,
            offering: profileOffering,
            tone: profileTone,
            emojiUsage: profileEmoji,
            sampleMessages: profileSamples
        )
        AIService.setUserProfile(profile)
    }

    private var templatesSection: some View {
        Section {
            NavigationLink {
                TemplatesView()
            } label: {
                Label("Message Templates", systemImage: "doc.text")
            }
        } header: {
            Text("Quick Messages")
        } footer: {
            Text("Pre-written messages you can quickly copy and send. Works offline, no AI needed.")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, newValue in
                    handleNotificationToggle(enabled: newValue)
                }

            if notificationsEnabled {
                Picker("Morning Reminder", selection: $morningReminderTime) {
                    ForEach(6...12, id: \.self) { hour in
                        Text("\(hour):00 AM").tag(hour)
                    }
                }
                .onChange(of: morningReminderTime) { _, newHour in
                    scheduleMorningReminder(hour: newHour)
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

    private var calendarSection: some View {
        Section {
            Toggle("Sync to Calendar", isOn: $calendarSyncEnabled)
                .onChange(of: calendarSyncEnabled) { _, newValue in
                    handleCalendarToggle(enabled: newValue)
                }

            if calendarSyncEnabled {
                HStack {
                    Text("Calendar")
                    Spacer()
                    Text("DMFlow Follow-Ups")
                        .foregroundStyle(.secondary)
                }

                let prospectsWithFollowUps = allProspects.filter { $0.nextFollowUp != nil }.count
                HStack {
                    Text("Synced Events")
                    Spacer()
                    Text("\(prospectsWithFollowUps)")
                        .foregroundStyle(.secondary)
                }
            }

            if calendarAuthDenied {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Calendar access denied. Enable in Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Calendar Integration")
        } footer: {
            Text("Add follow-up reminders to your iOS Calendar for visibility across all your devices.")
        }
    }

    private var iCloudSection: some View {
        Section {
            HStack {
                Image(systemName: cloudKitService.syncStatus.icon)
                    .foregroundStyle(syncStatusColor)
                    .symbolEffect(.pulse, isActive: cloudKitService.syncStatus == .syncing)
                Text("iCloud Sync")
                Spacer()
                Text(cloudKitService.syncStatus.displayText)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Account")
                Spacer()
                Text(cloudKitService.accountStatus.displayText)
                    .foregroundStyle(.secondary)
            }

            if cloudKitService.accountStatus == .available {
                HStack {
                    Text("Last Synced")
                    Spacer()
                    Text(cloudKitService.formattedLastSync)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task {
                        await cloudKitService.triggerSync()
                    }
                } label: {
                    HStack {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        if cloudKitService.syncStatus == .syncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(cloudKitService.syncStatus == .syncing)
            }

            if cloudKitService.accountStatus == .noAccount {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Sign in to iCloud in Settings to sync.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("iCloud Sync")
        } footer: {
            Text("Your prospects, templates, and activities sync automatically across all your devices signed into the same iCloud account.")
        }
    }

    private var syncStatusColor: Color {
        switch cloudKitService.syncStatus.color {
        case "green": return .green
        case "blue": return .blue
        case "red": return .red
        case "orange": return .orange
        default: return .secondary
        }
    }

    private func handleCalendarToggle(enabled: Bool) {
        if enabled {
            Task {
                let granted = await CalendarService.shared.requestAccess()
                if granted {
                    // Sync all existing follow-ups
                    CalendarService.shared.syncAllFollowUps(allProspects)
                    await MainActor.run {
                        calendarAuthDenied = false
                    }
                } else {
                    // Permission denied
                    await MainActor.run {
                        calendarSyncEnabled = false
                        calendarAuthDenied = true
                    }
                }
            }
        } else {
            // Remove all calendar events
            CalendarService.shared.removeAllEvents()
        }
    }

    private func handleNotificationToggle(enabled: Bool) {
        if enabled {
            Task {
                let granted = await NotificationService.shared.requestAuthorization()
                if granted {
                    // Schedule morning reminder with current counts
                    scheduleMorningReminder(hour: morningReminderTime)
                    // Schedule notifications for all existing follow-ups
                    scheduleAllFollowUpNotifications()
                } else {
                    // Permission denied, turn off toggle
                    await MainActor.run {
                        notificationsEnabled = false
                    }
                }
            }
        } else {
            // Cancel all notifications
            NotificationService.shared.cancelMorningReminder()
            cancelAllFollowUpNotifications()
        }
    }

    private func scheduleMorningReminder(hour: Int) {
        let overdueCount = allProspects.filter { $0.isOverdue }.count
        let todayCount = allProspects.filter { $0.isDueToday }.count
        NotificationService.shared.scheduleMorningReminder(
            hour: hour,
            overdueCount: overdueCount,
            todayCount: todayCount
        )
    }

    private func scheduleAllFollowUpNotifications() {
        for prospect in allProspects where prospect.nextFollowUp != nil {
            NotificationService.shared.scheduleFollowUpReminder(for: prospect)
        }
    }

    private func cancelAllFollowUpNotifications() {
        for prospect in allProspects {
            NotificationService.shared.cancelFollowUpReminder(for: prospect)
        }
    }

    private var aiSection: some View {
        Section {
            SecureField("OpenAI API Key", text: $apiKey)
                .textContentType(.password)
                .autocorrectionDisabled()
                .onChange(of: apiKey) { _, newValue in
                    AIService.setAPIKey(newValue)
                }

            HStack {
                Text("Status")
                Spacer()
                if apiKey.isEmpty {
                    Text("Not configured")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Configured")
                        .foregroundStyle(.green)
                }
            }
        } header: {
            Text("AI Features")
        } footer: {
            Text("Enter your OpenAI API key to enable AI message suggestions. Get a key at platform.openai.com")
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
                if usageTracker.canExport {
                    exportData()
                } else {
                    showingPaywall = true
                }
            } label: {
                HStack {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                    Spacer()
                    if !usageTracker.isPro {
                        Label("Pro", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
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
            #if DEBUG
            print("Export failed: \(error)")
            #endif
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

struct SampleMessagesEditor: View {
    @Binding var sampleMessages: String
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                TextEditor(text: $sampleMessages)
                    .frame(minHeight: 200)
                    .onChange(of: sampleMessages) { _, _ in
                        onSave()
                    }
            } header: {
                Text("Your Sample Messages")
            } footer: {
                Text("Paste 2-3 example DMs you've sent. The AI will analyze your writing style and match it when generating suggestions.\n\nExample:\n\"Hey! Saw your post about wanting more energy - totally get it! What's your biggest struggle with staying energized?\"\n\n\"Just checking in! How's everything going since we last chatted?\"")
            }
        }
        .navigationTitle("Sample Messages")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
