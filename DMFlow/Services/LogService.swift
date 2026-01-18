//
//  LogService.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import os.log

/// Centralized logging service using OSLog for production-ready diagnostics
enum Log {
    private static let subsystem = "com.ronnie.dmflow"

    // MARK: - Loggers by Category

    static let app = Logger(subsystem: subsystem, category: "App")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let cloudKit = Logger(subsystem: subsystem, category: "CloudKit")
    static let ai = Logger(subsystem: subsystem, category: "AI")
    static let calendar = Logger(subsystem: subsystem, category: "Calendar")
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
    static let subscription = Logger(subsystem: subsystem, category: "Subscription")
    static let widget = Logger(subsystem: subsystem, category: "Widget")
    static let templates = Logger(subsystem: subsystem, category: "Templates")
    static let share = Logger(subsystem: subsystem, category: "ShareExtension")
}
