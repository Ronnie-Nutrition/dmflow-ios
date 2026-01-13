//
//  DMFlowIntents.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import AppIntents
import SwiftData
import SwiftUI

// MARK: - Get Follow-Up Count Intent

struct GetFollowUpCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Follow-Up Count"
    static var description = IntentDescription("Check how many follow-ups you have today")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Prospect.self)
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Prospect>()
        let prospects = try context.fetch(descriptor)

        let overdueCount = prospects.filter { prospect in
            guard let followUp = prospect.nextFollowUp else { return false }
            return followUp < Calendar.current.startOfDay(for: Date()) &&
                   prospect.stage != .client && prospect.stage != .dnd
        }.count

        let todayCount = prospects.filter { prospect in
            guard let followUp = prospect.nextFollowUp else { return false }
            return Calendar.current.isDateInToday(followUp) &&
                   prospect.stage != .client && prospect.stage != .dnd
        }.count

        let hotLeadCount = prospects.filter { $0.isHotLead && $0.stage != .client && $0.stage != .dnd }.count

        let total = overdueCount + todayCount

        if total == 0 {
            return .result(dialog: "You're all caught up! No follow-ups due today.")
        } else {
            var message = "You have \(total) follow-up\(total == 1 ? "" : "s") to do"
            if overdueCount > 0 {
                message += " (\(overdueCount) overdue)"
            }
            if hotLeadCount > 0 {
                message += ". Plus \(hotLeadCount) hot lead\(hotLeadCount == 1 ? "" : "s") to prioritize"
            }
            message += "."
            return .result(dialog: "\(message)")
        }
    }
}

// MARK: - Add Prospect Intent

struct AddProspectIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Prospect"
    static var description = IntentDescription("Add a new prospect to DMFlow")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Name")
    var name: String

    @Parameter(title: "Platform", default: .instagram)
    var platform: PlatformEntity

    @Parameter(title: "Handle", description: "Social media username (optional)")
    var handle: String?

    @Parameter(title: "Hot Lead", default: false)
    var isHotLead: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Prospect.self)
        let context = ModelContext(container)

        let prospect = Prospect(
            name: name,
            handle: handle,
            platform: platform.toPlatform(),
            stage: .new,
            isHotLead: isHotLead
        )

        context.insert(prospect)
        try context.save()

        let platformName = platform.toPlatform().displayName
        return .result(dialog: "Added \(name) as a new prospect on \(platformName).")
    }
}

// MARK: - Start Power Hour Intent

struct StartPowerHourIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Power Hour"
    static var description = IntentDescription("Launch Power Hour mode to contact your prospects")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & OpensIntent {
        // Post notification to open Power Hour
        await MainActor.run {
            NotificationCenter.default.post(
                name: .openPowerHour,
                object: nil
            )
        }
        return .result()
    }
}

// MARK: - Open DMFlow Intent

struct OpenDMFlowIntent: AppIntent {
    static var title: LocalizedStringResource = "Open DMFlow"
    static var description = IntentDescription("Open the DMFlow app")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Get Hot Leads Intent

struct GetHotLeadsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Hot Leads"
    static var description = IntentDescription("List your current hot leads")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Prospect.self)
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Prospect>()
        let prospects = try context.fetch(descriptor)

        let hotLeads = prospects.filter { $0.isHotLead && $0.stage != .client && $0.stage != .dnd }

        if hotLeads.isEmpty {
            return .result(dialog: "You don't have any hot leads right now. Add some prospects and mark them as hot!")
        }

        let names = hotLeads.prefix(5).map { $0.name }.joined(separator: ", ")
        let count = hotLeads.count

        if count <= 5 {
            return .result(dialog: "Your hot leads are: \(names).")
        } else {
            return .result(dialog: "You have \(count) hot leads. Top ones: \(names), and \(count - 5) more.")
        }
    }
}

// MARK: - Platform Entity for App Intents

enum PlatformEntity: String, AppEnum {
    case instagram = "Instagram"
    case facebook = "Facebook"
    case sms = "SMS"
    case whatsapp = "WhatsApp"
    case other = "Other"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Platform"

    static var caseDisplayRepresentations: [PlatformEntity: DisplayRepresentation] = [
        .instagram: "Instagram",
        .facebook: "Facebook",
        .sms: "SMS",
        .whatsapp: "WhatsApp",
        .other: "Other"
    ]

    func toPlatform() -> Platform {
        switch self {
        case .instagram: return .instagram
        case .facebook: return .facebook
        case .sms: return .sms
        case .whatsapp: return .whatsapp
        case .other: return .other
        }
    }
}

// MARK: - App Shortcuts Provider

struct DMFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetFollowUpCountIntent(),
            phrases: [
                "How many follow-ups in \(.applicationName)",
                "Check my \(.applicationName) follow-ups",
                "What's my \(.applicationName) status",
                "\(.applicationName) today",
                "How many prospects need follow-up in \(.applicationName)"
            ],
            shortTitle: "Follow-Up Count",
            systemImageName: "person.2.fill"
        )

        AppShortcut(
            intent: AddProspectIntent(),
            phrases: [
                "Add a prospect in \(.applicationName)",
                "New prospect in \(.applicationName)",
                "Add someone to \(.applicationName)"
            ],
            shortTitle: "Add Prospect",
            systemImageName: "person.badge.plus"
        )

        AppShortcut(
            intent: StartPowerHourIntent(),
            phrases: [
                "Start Power Hour in \(.applicationName)",
                "Begin Power Hour with \(.applicationName)",
                "Let's do Power Hour in \(.applicationName)"
            ],
            shortTitle: "Power Hour",
            systemImageName: "bolt.fill"
        )

        AppShortcut(
            intent: GetHotLeadsIntent(),
            phrases: [
                "Who are my hot leads in \(.applicationName)",
                "Show hot leads in \(.applicationName)",
                "Get my hot leads from \(.applicationName)"
            ],
            shortTitle: "Hot Leads",
            systemImageName: "flame.fill"
        )

        AppShortcut(
            intent: OpenDMFlowIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Launch \(.applicationName)"
            ],
            shortTitle: "Open App",
            systemImageName: "app"
        )
    }
}
