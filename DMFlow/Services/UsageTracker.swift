//
//  UsageTracker.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation

@Observable
final class UsageTracker {
    static let shared = UsageTracker()

    private let defaults = UserDefaults.standard

    /// AI features are Pro-only - no free tier
    var canUseAI: Bool {
        isPro
    }

    var isPro: Bool {
        // TODO: Check StoreKit subscription status
        // For now, always return false (free tier)
        defaults.bool(forKey: "is_pro_user")
    }

    private init() {}

    // For testing Pro features during development
    func setPro(_ value: Bool) {
        defaults.set(value, forKey: "is_pro_user")
    }
}
