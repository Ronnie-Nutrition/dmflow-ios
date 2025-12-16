//
//  CloudKitService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import CloudKit

enum SyncStatus {
    case idle
    case syncing
    case synced
    case error(Error)
    case offline
}

final class CloudKitService {
    static let shared = CloudKitService()

    private let container = CKContainer(identifier: "iCloud.com.ronnie.dmflow")
    private let privateDatabase: CKDatabase

    @Published var syncStatus: SyncStatus = .idle
    @Published var isSignedIn: Bool = false

    private init() {
        privateDatabase = container.privateCloudDatabase
    }

    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                isSignedIn = status == .available
            }
        } catch {
            await MainActor.run {
                isSignedIn = false
            }
        }
    }

    func setupSubscriptions() async throws {
        let subscription = CKDatabaseSubscription(subscriptionID: "all-changes")

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true

        subscription.notificationInfo = notificationInfo

        do {
            try await privateDatabase.save(subscription)
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Subscription already exists
        }
    }

    func fetchChanges() async throws {
        await MainActor.run {
            syncStatus = .syncing
        }

        // SwiftData with CloudKit handles sync automatically
        // This method is for manual sync triggers if needed

        await MainActor.run {
            syncStatus = .synced
        }
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
