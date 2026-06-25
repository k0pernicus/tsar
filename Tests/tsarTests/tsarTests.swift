import Foundation
import Logging
import Testing

@testable import tsar

@Test func example() async throws {
    let logger = getlogger()

    var tmpDir: String = ""
    do {
        tmpDir = try createTestStructure(components: [
            .directory("MyDirectory", [.file("MyFile.txt")])
        ])
    } catch {
        logger.error("Failed to create test directory: \(error)")
        throw error
    }
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }
    logger.debug("Temporary directory created at \(tmpDir)")
}
