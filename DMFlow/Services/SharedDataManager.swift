//
//  SharedDataManager.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation

struct PendingProspect: Codable {
    let id: String
    let name: String
    let handle: String?
    let platform: String
    let stage: String
    let notes: String?
    let isHotLead: Bool
    let createdAt: Date
}

final class SharedDataManager {
    static let shared = SharedDataManager()

    private let appGroupIdentifier = "group.com.ronnie.dmflow"
    private let pendingProspectsKey = "pendingProspects"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Save from Share Extension

    func savePendingProspect(_ prospect: PendingProspect) {
        var pending = getPendingProspects()
        pending.append(prospect)

        if let data = try? JSONEncoder().encode(pending) {
            sharedDefaults?.set(data, forKey: pendingProspectsKey)
        }
    }

    // MARK: - Read from Main App

    func getPendingProspects() -> [PendingProspect] {
        guard let data = sharedDefaults?.data(forKey: pendingProspectsKey),
              let prospects = try? JSONDecoder().decode([PendingProspect].self, from: data) else {
            return []
        }
        return prospects
    }

    func clearPendingProspects() {
        sharedDefaults?.removeObject(forKey: pendingProspectsKey)
    }

    func removePendingProspect(withId id: String) {
        var pending = getPendingProspects()
        pending.removeAll { $0.id == id }

        if let data = try? JSONEncoder().encode(pending) {
            sharedDefaults?.set(data, forKey: pendingProspectsKey)
        }
    }

    var hasPendingProspects: Bool {
        !getPendingProspects().isEmpty
    }

    var pendingCount: Int {
        getPendingProspects().count
    }
}
