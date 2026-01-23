//
//  SubscriptionManager.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import Foundation
import StoreKit
import os.log

@Observable
@MainActor
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false

    private let productIDs = [
        "com.ronnie.dmflow.pro.monthly",
        "com.ronnie.dmflow.pro.annual"
    ]

    var isPro: Bool {
        !purchasedProductIDs.isEmpty
    }

    var monthlyProduct: Product? {
        products.first { $0.id == "com.ronnie.dmflow.pro.monthly" }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == "com.ronnie.dmflow.pro.annual" }
    }

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            Log.subscription.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            Log.subscription.error("Failed to restore purchases: \(error.localizedDescription)")
        }
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)
                    await self?.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    Log.subscription.error("Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        }
    }
}
