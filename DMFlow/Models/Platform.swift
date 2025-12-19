//
//  Platform.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import SwiftUI

enum Platform: String, Codable, CaseIterable, Identifiable {
    case instagram
    case facebook
    case sms
    case whatsapp
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        case .sms: return "SMS"
        case .whatsapp: return "WhatsApp"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .facebook: return "person.2.fill"
        case .sms: return "message.fill"
        case .whatsapp: return "phone.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .instagram: return Color(red: 0.88, green: 0.19, blue: 0.42)
        case .facebook: return Color(red: 0.23, green: 0.35, blue: 0.60)
        case .sms: return Color.green
        case .whatsapp: return Color(red: 0.15, green: 0.68, blue: 0.38)
        case .other: return Color.gray
        }
    }

    /// Returns the URL to open the user's profile on this platform
    func profileURL(for handle: String) -> URL? {
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
        switch self {
        case .instagram:
            // Try app first, falls back to web
            return URL(string: "https://instagram.com/\(cleanHandle)")
        case .facebook:
            return URL(string: "https://facebook.com/\(cleanHandle)")
        case .whatsapp:
            // WhatsApp needs phone number format
            let phoneNumber = cleanHandle.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            guard !phoneNumber.isEmpty else { return nil }
            return URL(string: "https://wa.me/\(phoneNumber)")
        case .sms:
            let phoneNumber = cleanHandle.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            guard !phoneNumber.isEmpty else { return nil }
            return URL(string: "sms:\(phoneNumber)")
        case .other:
            return nil
        }
    }

    /// Whether this platform supports direct profile links
    var supportsProfileLink: Bool {
        switch self {
        case .instagram, .facebook, .whatsapp, .sms:
            return true
        case .other:
            return false
        }
    }
}
