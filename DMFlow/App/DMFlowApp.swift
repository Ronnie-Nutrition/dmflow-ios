//
//  DMFlowApp.swift
//  DMFlow
//
//  Created by Ronnie Craig
//  DMFlow - DM Prospect Tracker for Network Marketers
//

import SwiftUI
import SwiftData

@main
struct DMFlowApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Prospect.self,
                MessageTemplate.self
            ])
            // Use local storage only for now (CloudKit can be enabled later)
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Populate built-in templates on first launch
            let context = ModelContext(modelContainer)
            TemplateService.shared.populateBuiltInTemplates(in: context)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
