//
//  ShareViewController.swift
//  DMFlowShare
//
//  Created by Ronnie Craig
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private var sharedText: String?
    private var sharedURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        extractSharedContent()
    }

    private func extractSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            showAddProspectView(prefillName: nil, prefillHandle: nil, prefillPlatform: nil)
            return
        }

        let textType = UTType.plainText.identifier
        let urlType = UTType.url.identifier

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(textType) {
                attachment.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] item, _ in
                    if let text = item as? String {
                        self?.sharedText = text
                        DispatchQueue.main.async {
                            self?.processSharedContent()
                        }
                    }
                }
                return
            } else if attachment.hasItemConformingToTypeIdentifier(urlType) {
                attachment.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] item, _ in
                    if let url = item as? URL {
                        self?.sharedURL = url
                        DispatchQueue.main.async {
                            self?.processSharedContent()
                        }
                    }
                }
                return
            }
        }

        // Fallback if no supported content
        DispatchQueue.main.async { [weak self] in
            self?.showAddProspectView(prefillName: nil, prefillHandle: nil, prefillPlatform: nil)
        }
    }

    private func processSharedContent() {
        var name: String?
        var handle: String?
        var platform: SharePlatform?

        // Process text content
        if let text = sharedText {
            // Check if text contains a URL
            if let urlFromText = extractURL(from: text) {
                let result = parseURL(urlFromText)
                handle = result.handle
                platform = result.platform
            } else if text.hasPrefix("@") {
                handle = String(text.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if text.contains("@") && !text.contains(" ") {
                // Likely a handle like user@handle format
                let parts = text.split(separator: "@")
                if parts.count >= 2 {
                    handle = String(parts.last ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else {
                // Treat as name
                name = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Process URL content (takes priority over text for handle/platform)
        if let url = sharedURL {
            let result = parseURL(url)
            if let parsedHandle = result.handle {
                handle = parsedHandle
            }
            if let parsedPlatform = result.platform {
                platform = parsedPlatform
            }
        }

        showAddProspectView(prefillName: name, prefillHandle: handle, prefillPlatform: platform)
    }

    // MARK: - URL Parsing

    /// Extracts a URL from text if present
    private func extractURL(from text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        if let match = detector?.firstMatch(in: text, options: [], range: range),
           let url = match.url {
            return url
        }
        return nil
    }

    /// Parses a URL to extract handle and platform
    private func parseURL(_ url: URL) -> (handle: String?, platform: SharePlatform?) {
        let urlString = url.absoluteString.lowercased()
        let host = url.host?.lowercased() ?? ""

        // Instagram
        if host.contains("instagram.com") || host.contains("instagr.am") {
            return parseInstagramURL(url)
        }

        // Facebook
        if host.contains("facebook.com") || host.contains("fb.com") || host.contains("fb.me") {
            return parseFacebookURL(url)
        }

        // TikTok
        if host.contains("tiktok.com") || host.contains("vm.tiktok.com") {
            return parseTikTokURL(url)
        }

        // Twitter/X
        if host.contains("twitter.com") || host.contains("x.com") || host.contains("t.co") {
            return parseTwitterURL(url)
        }

        // LinkedIn
        if host.contains("linkedin.com") || host.contains("lnkd.in") {
            return parseLinkedInURL(url)
        }

        // WhatsApp
        if host.contains("wa.me") || host.contains("whatsapp.com") || urlString.contains("whatsapp") {
            return parseWhatsAppURL(url)
        }

        return (nil, nil)
    }

    private func parseInstagramURL(_ url: URL) -> (handle: String?, platform: SharePlatform?) {
        let path = url.path
        let components = path.split(separator: "/").filter { !$0.isEmpty }

        // Filter out non-username paths
        let ignoredPaths = ["p", "reel", "reels", "stories", "explore", "direct", "accounts", "about", "tv"]

        if let firstComponent = components.first {
            let componentString = String(firstComponent).lowercased()
            if !ignoredPaths.contains(componentString) {
                let handle = cleanHandle(String(firstComponent))
                return (handle, .instagram)
            }
        }

        return (nil, .instagram)
    }

    private func parseFacebookURL(_ url: URL) -> (handle: String?, platform: SharePlatform?) {
        let path = url.path
        let components = path.split(separator: "/").filter { !$0.isEmpty }

        // Filter out non-username paths
        let ignoredPaths = ["groups", "pages", "events", "marketplace", "watch", "gaming", "profile.php", "sharer", "share"]

        if let firstComponent = components.first {
            let componentString = String(firstComponent).lowercased()
            if !ignoredPaths.contains(componentString) {
                let handle = cleanHandle(String(firstComponent))
                return (handle, .facebook)
            }
        }

        // Check for profile.php?id= format
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let idValue = queryItems.first(where: { $0.name == "id" })?.value {
            return (idValue, .facebook)
        }

        return (nil, .facebook)
    }

    private func parseTikTokURL(_ url: URL) -> (handle: String?, platform: SharePlatform?) {
        let path = url.path
        let components = path.split(separator: "/").filter { !$0.isEmpty }

        // TikTok usernames start with @, path is /@username
        if let firstComponent = components.first {
            var username = String(firstComponent)
            if username.hasPrefix("@") {
                username = String(username.dropFirst())
            }
            let handle = cleanHandle(username)
            // Return as "other" since we don't have TikTok platform
            return (handle, .other)
        }

        return (nil, .other)
    }

    private func parseTwitterURL(_ url: URL) -> (handle: String?, platform: SharePlatform?) {
        let path = url.path
        let components = path.split(separator: "/").filter { !$0.isEmpty }

        // Filter out non-username paths
        let ignoredPaths = ["i", "intent", "search", "explore", "home", "notifications", "messages", "settings", "hashtag", "compose"]

        if let firstComponent = components.first {
            let componentString = String(firstComponent).lowercased()
            if !ignoredPaths.contains(componentString) {
                let handle = cleanHandle(String(firstComponent))
                // Return as "other" since we don't have Twitter platform
                return (handle, .other)
            }
        }

        return (nil, .other)
    }

    private func parseLinkedInURL(_ url: URL) -> (handle: String?, platform: SharePlatform?) {
        let path = url.path
        let components = path.split(separator: "/").filter { !$0.isEmpty }

        // LinkedIn profile URLs: /in/username
        if components.count >= 2 && String(components[0]).lowercased() == "in" {
            let handle = cleanHandle(String(components[1]))
            // Return as "other" since we don't have LinkedIn platform
            return (handle, .other)
        }

        return (nil, .other)
    }

    private func parseWhatsAppURL(_ url: URL) -> (handle: String?, platform: SharePlatform?) {
        // wa.me/1234567890 format
        let path = url.path
        let components = path.split(separator: "/").filter { !$0.isEmpty }

        if let phoneNumber = components.first {
            let cleaned = String(phoneNumber).replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            if !cleaned.isEmpty {
                return (cleaned, .whatsapp)
            }
        }

        // Check query params for phone
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let phone = queryItems.first(where: { $0.name == "phone" })?.value {
            return (phone, .whatsapp)
        }

        return (nil, .whatsapp)
    }

    /// Cleans a handle by removing query params, fragments, and trimming
    private func cleanHandle(_ handle: String) -> String {
        var cleaned = handle

        // Remove query string if present
        if let queryIndex = cleaned.firstIndex(of: "?") {
            cleaned = String(cleaned[..<queryIndex])
        }

        // Remove fragment if present
        if let fragmentIndex = cleaned.firstIndex(of: "#") {
            cleaned = String(cleaned[..<fragmentIndex])
        }

        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove trailing slash
        if cleaned.hasSuffix("/") {
            cleaned = String(cleaned.dropLast())
        }

        return cleaned
    }

    // MARK: - View Presentation

    private func showAddProspectView(prefillName: String?, prefillHandle: String?, prefillPlatform: SharePlatform?) {
        let hostingController = UIHostingController(
            rootView: ShareExtensionView(
                prefillName: prefillName,
                prefillHandle: prefillHandle,
                prefillPlatform: prefillPlatform,
                onSave: { [weak self] in
                    self?.extensionContext?.completeRequest(returningItems: nil)
                },
                onCancel: { [weak self] in
                    self?.extensionContext?.cancelRequest(withError: NSError(domain: "com.ronnie.dmflow", code: 0))
                }
            )
        )

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}
