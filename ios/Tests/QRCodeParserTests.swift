import XCTest
@testable import SmartLibrary

final class QRCodeParserTests: XCTestCase {
    let demoLibraryId = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!

    func testValidEntryQRParsing() throws {
        let raw = "SLMS|ENTRY|11111111-1111-4111-8111-111111111111"
        let payload = try QRParser.parse(raw, expectedLibraryId: demoLibraryId)
        XCTAssertEqual(payload.type, .entry)
        XCTAssertEqual(payload.libraryId, demoLibraryId)
    }

    func testValidExitQRParsing() throws {
        let raw = "SLMS|EXIT|11111111-1111-4111-8111-111111111111"
        let payload = try QRParser.parse(raw, expectedLibraryId: demoLibraryId)
        XCTAssertEqual(payload.type, .exit)
        XCTAssertEqual(payload.libraryId, demoLibraryId)
    }

    func testWhitespaceTrimming() throws {
        let raw = "  SLMS|ENTRY|11111111-1111-4111-8111-111111111111 \n "
        let payload = try QRParser.parse(raw, expectedLibraryId: demoLibraryId)
        XCTAssertEqual(payload.type, .entry)
        XCTAssertEqual(payload.libraryId, demoLibraryId)
    }

    func testInvalidPrefix() {
        let raw = "OTHER|ENTRY|11111111-1111-4111-8111-111111111111"
        XCTAssertThrowsError(try QRParser.parse(raw, expectedLibraryId: demoLibraryId)) { error in
            XCTAssertEqual(error as? QRParseError, .invalidFormat)
        }
    }

    func testMalformedFormat() {
        let raw = "SLMS|ENTRY"
        XCTAssertThrowsError(try QRParser.parse(raw, expectedLibraryId: demoLibraryId)) { error in
            XCTAssertEqual(error as? QRParseError, .invalidFormat)
        }
    }

    func testUnknownActionType() {
        let raw = "SLMS|UNKNOWN|11111111-1111-4111-8111-111111111111"
        XCTAssertThrowsError(try QRParser.parse(raw, expectedLibraryId: demoLibraryId)) { error in
            XCTAssertEqual(error as? QRParseError, .unknownType("UNKNOWN"))
        }
    }

    func testInvalidUUID() {
        let raw = "SLMS|ENTRY|not-a-valid-uuid"
        XCTAssertThrowsError(try QRParser.parse(raw, expectedLibraryId: demoLibraryId)) { error in
            XCTAssertEqual(error as? QRParseError, .invalidUUID("not-a-valid-uuid"))
        }
    }

    func testUnsupportedLibrary() {
        let otherLib = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
        let raw = "SLMS|ENTRY|\(otherLib.uuidString)"
        XCTAssertThrowsError(try QRParser.parse(raw, expectedLibraryId: demoLibraryId)) { error in
            XCTAssertEqual(error as? QRParseError, .unsupportedLibrary(otherLib))
        }
    }
}
