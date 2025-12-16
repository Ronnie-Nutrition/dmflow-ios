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
}
