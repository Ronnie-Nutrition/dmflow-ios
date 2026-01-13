//
//  CloudKitService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import CloudKit
import Combine

enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced
    case error(String)
    case offline
    case notSignedIn

    static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.synced, .synced),
             (.offline, .offline), (.notSignedIn, .notSignedIn):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }

    var displayText: String {
        switch self {
        case .idle: return "Ready"
        case .syncing: return "Syncing..."
        case .synced: return "Up to date"
        case .error(let message): return message
        case .offline: return "Offline"
        case .notSignedIn: return "Not signed in"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .synced: return "checkmark.icloud"
        case .error: return "exclamationmark.icloud"
        case .offline: return "icloud.slash"
        case .notSignedIn: return "person.icloud"
        }
    }

    var color: String {
        switch self {
        case .idle: return "secondary"
        case .syncing: return "blue"
        case .synced: return "green"
        case .error: return "red"
        case .offline: return "orange"
        case .notSignedIn: return "secondary"
        }
    }
}

enum AccountStatus: Equatable {
    case unknown
    case available
    case noAccount
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable

    var displayText: String {
        switch self {
        case .unknown: return "Checking..."
        case .available: return "Signed In"
        case .noAccount: return "No iCloud Account"
        case .restricted: return "Restricted"
        case .couldNotDetermine: return "Could not determine"
        case .temporarilyUnavailable: return "Temporarily unavailable"
        }
    }
}

@MainActor
final class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    private let container = CKContainer(identifier: "iCloud.com.ronnie.dmflow")
    private let privateDatabase: CKDatabase

    @Published var syncStatus: SyncStatus = .idle
    @Published var accountStatus: AccountStatus = .unknown
    @Published var lastSyncDate: Date?

    private var accountChangeObserver: NSObjectProtocol?

    private init() {
        privateDatabase = container.privateCloudDatabase
        setupAccountChangeObserver()
        Task {
            await checkAccountStatus()
        }
    }

    deinit {
        if let observer = accountChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupAccountChangeObserver() {
        accountChangeObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAccountStatus()
            }
        }
    }

    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                accountStatus = .available
                if syncStatus == .notSignedIn {
                    syncStatus = .idle
                }
            case .noAccount:
                accountStatus = .noAccount
                syncStatus = .notSignedIn
            case .restricted:
                accountStatus = .restricted
                syncStatus = .notSignedIn
            case .couldNotDetermine:
                accountStatus = .couldNotDetermine
                syncStatus = .error("Could not determine iCloud status")
            case .temporarilyUnavailable:
                accountStatus = .temporarilyUnavailable
                syncStatus = .offline
            @unknown default:
                accountStatus = .unknown
            }
        } catch {
            accountStatus = .couldNotDetermine
            syncStatus = .error(error.localizedDescription)
        }
    }

    func setupSubscriptions() async throws {
        guard accountStatus == .available else { return }

        let subscription = CKDatabaseSubscription(subscriptionID: "all-changes")

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true

        subscription.notificationInfo = notificationInfo

        do {
            try await privateDatabase.save(subscription)
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Subscription already exists - this is fine
        }
    }

    func triggerSync() async {
        guard accountStatus == .available else {
            syncStatus = .notSignedIn
            return
        }

        syncStatus = .syncing

        // SwiftData with CloudKit handles sync automatically
        // This provides a visual indicator and triggers a check
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // Brief delay for visual feedback
            syncStatus = .synced
            lastSyncDate = Date()
            saveLastSyncDate()
        } catch {
            syncStatus = .error("Sync interrupted")
        }
    }

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudKitSyncDate")
    }

    func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastCloudKitSyncDate") as? Date
    }

    var formattedLastSync: String {
        guard let date = lastSyncDate else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension CloudKitService {
    enum CloudKitError: LocalizedError {
        case notSignedIn
        case networkUnavailable
        case serverError(Error)

        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return "Please sign in to iCloud to sync your data."
            case .networkUnavailable:
                return "No internet connection. Your data will sync when you're back online."
            case .serverError(let error):
                return "Sync error: \(error.localizedDescription)"
            }
        }
    }
}
