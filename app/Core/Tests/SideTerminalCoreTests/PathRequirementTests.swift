import XCTest
@testable import SideTerminalCore

final class PathRequirementTests: XCTestCase {
    func testDirectoryAcceptsExistingFolder() {
        let tmp = NSTemporaryDirectory()
        XCTAssertTrue(PathRequirement.directory.validate(tmp))
    }

    func testDirectoryAcceptsTilde() {
        XCTAssertTrue(PathRequirement.directory.validate("~"))
    }

    func testDirectoryRejectsFile() throws {
        let file = NSTemporaryDirectory() + "sideterminal-test-\(UUID().uuidString).txt"
        try "hi".write(toFile: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: file) }
        XCTAssertFalse(PathRequirement.directory.validate(file))
    }

    func testDirectoryRejectsMissingPath() {
        XCTAssertFalse(PathRequirement.directory.validate("/no/such/path/\(UUID().uuidString)"))
    }

    func testExecutableAcceptsShell() {
        XCTAssertTrue(PathRequirement.executable.validate("/bin/sh"))
    }

    func testExecutableRejectsPlainFile() throws {
        let file = NSTemporaryDirectory() + "sideterminal-test-\(UUID().uuidString).txt"
        try "not executable".write(toFile: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: file) }
        XCTAssertFalse(PathRequirement.executable.validate(file))
    }

    func testExecutableRejectsMissingPath() {
        XCTAssertFalse(PathRequirement.executable.validate("/usr/bin/\(UUID().uuidString)"))
    }
}
