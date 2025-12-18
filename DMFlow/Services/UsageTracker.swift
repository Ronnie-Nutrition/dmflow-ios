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

    /// AI features are Pro-only - no free tier
    var canUseAI: Bool {
        isPro
    }

    var isPro: Bool {
        SubscriptionManager.shared.isPro
    }

    private init() {}
}
