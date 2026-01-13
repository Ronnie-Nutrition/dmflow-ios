//
//  DMFlowApp.swift
//  DMFlow
//
//  Created by Ronnie Craig
//  DMFlow - DM Prospect Tracker for Network Marketers
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct DMFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Prospect.self,
            MessageTemplate.self,
            ProspectActivity.self
        ])

        // Try CloudKit first, fall back to local if it fails
        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [cloudConfig]
            )
            print("DMFlow: Using iCloud sync")
        } catch {
            // CloudKit failed - fall back to local storage
            print("DMFlow: CloudKit failed (\(error.localizedDescription)), using local storage")
            do {
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [localConfig]
                )
            } catch {
                fatalError("Could not initialize ModelContainer: \(error)")
            }
        }

        // Populate built-in templates on first launch
        let context = ModelContext(modelContainer)
        TemplateService.shared.populateBuiltInTemplates(in: context)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification authorization if enabled in settings
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if notificationsEnabled {
            Task {
                await NotificationService.shared.requestAuthorization()
            }
        }

        return true
    }

    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle prospect-specific notification
        if let prospectIdString = userInfo["prospectId"] as? String {
            // Post notification for the app to handle navigation
            NotificationCenter.default.post(
                name: .openProspect,
                object: nil,
                userInfo: ["prospectId": prospectIdString]
            )
        }

        // Clear badge on interaction
        NotificationService.shared.clearBadge()

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openProspect = Notification.Name("openProspect")
    static let openPowerHour = Notification.Name("openPowerHour")
}
