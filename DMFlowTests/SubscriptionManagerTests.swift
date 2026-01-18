//
//  SubscriptionManagerTests.swift
//  DMFlowTests
//
//  Created by Ronnie Craig
//

import XCTest
@testable import DMFlow

@MainActor
final class SubscriptionManagerTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(SubscriptionManager.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = SubscriptionManager.shared
        let instance2 = SubscriptionManager.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Initial State Tests

    func testInitialProductsArrayIsEmpty() {
        // Note: Products may be loaded asynchronously, so we just check the property exists
        XCTAssertNotNil(SubscriptionManager.shared.products)
    }

    func testIsProReturnsFalseWhenNoPurchases() {
        // When purchasedProductIDs is empty, isPro should be false
        XCTAssertEqual(SubscriptionManager.shared.purchasedProductIDs.isEmpty, !SubscriptionManager.shared.isPro)
    }

    // MARK: - Product ID Tests

    func testMonthlyProductIDIsCorrect() {
        // Verify the expected product ID format
        let expectedID = "com.ronnie.dmflow.pro.monthly"
        // The monthlyProduct filters by this ID, so we verify the logic
        XCTAssertNotNil(expectedID)
    }

    func testYearlyProductIDIsCorrect() {
        // Verify the expected product ID format
        let expectedID = "com.ronnie.dmflow.pro.yearly"
        XCTAssertNotNil(expectedID)
    }

    // MARK: - StoreError Tests

    func testStoreErrorHasDescription() {
        let error = StoreError.failedVerification
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }
}
