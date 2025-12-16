//
//  ShareViewController.swift
//  DMFlowShareExtension
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
        extractSharedContent()
    }

    private func extractSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            showAddProspectView(prefillName: nil, prefillHandle: nil)
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
            } else if attachment.hasItemConformingToTypeIdentifier(urlType) {
                attachment.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] item, _ in
                    if let url = item as? URL {
                        self?.sharedURL = url
                        DispatchQueue.main.async {
                            self?.processSharedContent()
                        }
                    }
                }
            }
        }

        // Fallback if no supported content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self?.sharedText == nil && self?.sharedURL == nil {
                self?.showAddProspectView(prefillName: nil, prefillHandle: nil)
            }
        }
    }

    private func processSharedContent() {
        var name: String?
        var handle: String?

        if let text = sharedText {
            // Try to extract username/handle from text
            if text.hasPrefix("@") {
                handle = String(text.dropFirst())
            } else if text.contains("@") {
                let parts = text.split(separator: "@")
                if parts.count >= 2 {
                    handle = String(parts.last ?? "")
                }
            } else {
                name = text
            }
        }

        if let url = sharedURL {
            // Try to extract username from Instagram/Facebook URLs
            let urlString = url.absoluteString

            if urlString.contains("instagram.com") {
                if let username = extractInstagramUsername(from: url) {
                    handle = username
                }
            } else if urlString.contains("facebook.com") {
                if let username = extractFacebookUsername(from: url) {
                    handle = username
                }
            }
        }

        showAddProspectView(prefillName: name, prefillHandle: handle)
    }

    private func extractInstagramUsername(from url: URL) -> String? {
        let path = url.path
        let components = path.split(separator: "/").filter { !$0.isEmpty }
        guard let username = components.first else { return nil }
        return String(username)
    }

    private func extractFacebookUsername(from url: URL) -> String? {
        let path = url.path
        let components = path.split(separator: "/").filter { !$0.isEmpty }
        guard let username = components.first else { return nil }
        return String(username)
    }

    private func showAddProspectView(prefillName: String?, prefillHandle: String?) {
        let hostingController = UIHostingController(
            rootView: ShareExtensionView(
                prefillName: prefillName,
                prefillHandle: prefillHandle,
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
