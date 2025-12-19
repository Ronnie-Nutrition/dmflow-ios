//
//  UsageTracker.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation

@Observable
@MainActor
final class UsageTracker {
    static let shared = UsageTracker()

    /// Free tier prospect limit
    static let freeProspectLimit = 15

    /// AI features are Pro-only - no free tier
    var canUseAI: Bool {
        isPro
    }

    var isPro: Bool {
        SubscriptionManager.shared.isPro
    }

    /// Check if user can add more prospects
    func canAddProspect(currentCount: Int) -> Bool {
        if isPro {
            return true
        }
        return currentCount < UsageTracker.freeProspectLimit
    }

    /// Get remaining prospect slots for free tier
    func remainingProspectSlots(currentCount: Int) -> Int {
        if isPro {
            return Int.max
        }
        return max(0, UsageTracker.freeProspectLimit - currentCount)
    }

    // MARK: - Shared App Group Data (for Share Extension)

    private let sharedDefaults = UserDefaults(suiteName: "group.com.ronnie.dmflow")
    private let proStatusKey = "isPro"
    private let prospectCountKey = "prospectCount"

    /// Sync current status to shared UserDefaults for Share Extension access
    func syncToSharedDefaults(prospectCount: Int) {
        sharedDefaults?.set(isPro, forKey: proStatusKey)
        sharedDefaults?.set(prospectCount, forKey: prospectCountKey)
        sharedDefaults?.synchronize()
    }

    /// Get shared data for Share Extension (static for use without MainActor)
    static func getSharedProStatus() -> Bool {
        let defaults = UserDefaults(suiteName: "group.com.ronnie.dmflow")
        return defaults?.bool(forKey: "isPro") ?? false
    }

    static func getSharedProspectCount() -> Int {
        let defaults = UserDefaults(suiteName: "group.com.ronnie.dmflow")
        return defaults?.integer(forKey: "prospectCount") ?? 0
    }

    private init() {}
}
