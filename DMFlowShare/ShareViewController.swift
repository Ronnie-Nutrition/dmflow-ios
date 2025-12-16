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
            self?.showAddProspectView(prefillName: nil, prefillHandle: nil)
        }
    }

    private func processSharedContent() {
        var name: String?
        var handle: String?

        if let text = sharedText {
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
            let urlString = url.absoluteString

            if urlString.contains("instagram.com") {
                let path = url.path
                let components = path.split(separator: "/").filter { !$0.isEmpty }
                if let username = components.first {
                    handle = String(username)
                }
            } else if urlString.contains("facebook.com") {
                let path = url.path
                let components = path.split(separator: "/").filter { !$0.isEmpty }
                if let username = components.first {
                    handle = String(username)
                }
            }
        }

        showAddProspectView(prefillName: name, prefillHandle: handle)
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
