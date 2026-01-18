//
//  KeychainServiceTests.swift
//  DMFlowTests
//
//  Created by Ronnie Craig
//

import XCTest
@testable import DMFlow

final class KeychainServiceTests: XCTestCase {

    private let testKey = "test_keychain_key"

    override func tearDown() {
        // Clean up test data
        try? KeychainService.delete(key: testKey)
        super.tearDown()
    }

    // MARK: - Save Tests

    func testSaveStringSucceeds() throws {
        let testValue = "test_secret_value"

        XCTAssertNoThrow(try KeychainService.save(key: testKey, string: testValue))

        let retrieved = KeychainService.readString(key: testKey)
        XCTAssertEqual(retrieved, testValue)
    }

    func testSaveDataSucceeds() throws {
        let testData = "test_data".data(using: .utf8)!

        XCTAssertNoThrow(try KeychainService.save(key: testKey, data: testData))

        let retrieved = try KeychainService.read(key: testKey)
        XCTAssertEqual(retrieved, testData)
    }

    func testSaveUpdatesExistingValue() throws {
        let initialValue = "initial_value"
        let updatedValue = "updated_value"

        try KeychainService.save(key: testKey, string: initialValue)
        try KeychainService.save(key: testKey, string: updatedValue)

        let retrieved = KeychainService.readString(key: testKey)
        XCTAssertEqual(retrieved, updatedValue)
    }

    // MARK: - Read Tests

    func testReadNonExistentKeyReturnsNil() {
        let result = KeychainService.readString(key: "non_existent_key")
        XCTAssertNil(result)
    }

    func testReadNonExistentKeyThrowsNotFound() {
        XCTAssertThrowsError(try KeychainService.read(key: "non_existent_key")) { error in
            XCTAssertTrue(error is KeychainService.KeychainError)
        }
    }

    // MARK: - Delete Tests

    func testDeleteExistingKey() throws {
        try KeychainService.save(key: testKey, string: "value_to_delete")

        XCTAssertNoThrow(try KeychainService.delete(key: testKey))

        let result = KeychainService.readString(key: testKey)
        XCTAssertNil(result)
    }

    func testDeleteNonExistentKeyDoesNotThrow() {
        XCTAssertNoThrow(try KeychainService.delete(key: "non_existent_key"))
    }

    // MARK: - Exists Tests

    func testExistsReturnsTrueForExistingKey() throws {
        try KeychainService.save(key: testKey, string: "test_value")

        XCTAssertTrue(KeychainService.exists(key: testKey))
    }

    func testExistsReturnsFalseForNonExistentKey() {
        XCTAssertFalse(KeychainService.exists(key: "non_existent_key"))
    }

    // MARK: - Edge Cases

    func testSaveEmptyString() throws {
        try KeychainService.save(key: testKey, string: "")

        let retrieved = KeychainService.readString(key: testKey)
        XCTAssertEqual(retrieved, "")
    }

    func testSaveSpecialCharacters() throws {
        let specialValue = "!@#$%^&*()_+-=[]{}|;':\",./<>?`~"

        try KeychainService.save(key: testKey, string: specialValue)

        let retrieved = KeychainService.readString(key: testKey)
        XCTAssertEqual(retrieved, specialValue)
    }

    func testSaveUnicodeCharacters() throws {
        let unicodeValue = "Hello 你好 🎉 مرحبا"

        try KeychainService.save(key: testKey, string: unicodeValue)

        let retrieved = KeychainService.readString(key: testKey)
        XCTAssertEqual(retrieved, unicodeValue)
    }
}
