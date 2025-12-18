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

    private let freeMonthlyLimit = 10
    private let defaults = UserDefaults.standard

    private let usageCountKey = "ai_usage_count"
    private let usageMonthKey = "ai_usage_month"

    private(set) var usageCount: Int {
        didSet {
            defaults.set(usageCount, forKey: usageCountKey)
        }
    }

    private(set) var usageMonth: String {
        didSet {
            defaults.set(usageMonth, forKey: usageMonthKey)
        }
    }

    var canUseAI: Bool {
        resetIfNewMonth()
        return usageCount < freeMonthlyLimit || isPro
    }

    var remainingUses: Int {
        resetIfNewMonth()
        return max(0, freeMonthlyLimit - usageCount)
    }

    var isPro: Bool {
        // TODO: Check StoreKit subscription status
        // For now, always return false (free tier)
        defaults.bool(forKey: "is_pro_user")
    }

    private init() {
        self.usageCount = defaults.integer(forKey: usageCountKey)
        self.usageMonth = defaults.string(forKey: usageMonthKey) ?? ""
        resetIfNewMonth()
    }

    func recordUsage() {
        resetIfNewMonth()
        usageCount += 1
    }

    private func resetIfNewMonth() {
        let currentMonth = Self.currentMonthString()
        if usageMonth != currentMonth {
            usageMonth = currentMonth
            usageCount = 0
        }
    }

    private static func currentMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    // For testing/development
    func resetUsage() {
        usageCount = 0
    }

    // For testing Pro features
    func setPro(_ value: Bool) {
        defaults.set(value, forKey: "is_pro_user")
    }
}
