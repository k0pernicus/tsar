import Foundation
import Tar
import Testing

@testable import tsar

// MARK: - Unarchive Command Tests

@Test func unarchiveSimpleArchive() async throws {
    let tmpDir = try createTestStructure(components: [
        .directory(
            "MyApp",
            [
                .file("main.swift"),
                .file("README.md"),
            ])
    ])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "MyApp/").path
    let archivePath = buildPath(folder: URL(string: tmpDir)!, filename: "output.tar").path
    defer { try? FileManager.default.removeItem(atPath: archivePath) }

    // Create the archive first
    var archiveCommand = try Archive.parse([testDirPath, archivePath])
    archiveCommand.allowOverride = true
    archiveCommand.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: archivePath))

    // Extract to a different directory
    let extractDir = buildPath(folder: URL(string: tmpDir)!, filename: "extracted").path
    defer { try? FileManager.default.removeItem(atPath: extractDir) }

    var unarchiveCommand = try Unarchive.parse([archivePath, extractDir])
    unarchiveCommand.run()

    let tmpDirs = try FileManager.default.contentsOfDirectory(atPath: extractDir)
    #expect(tmpDirs.count == 1)
    #expect(tmpDirs.contains("MyApp"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/MyApp/main.swift"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/MyApp/README.md"))
}

@Test func unarchiveEmptyArchive() async throws {
    let tmpDir = try createTestStructure(components: [.directory("Empty", [.none])])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "Empty").path
    let archivePath = buildPath(folder: URL(string: tmpDir)!, filename: "empty.tar").path
    defer { try? FileManager.default.removeItem(atPath: archivePath) }

    #expect(FileManager.default.fileExists(atPath: tmpDir))
    #expect(FileManager.default.fileExists(atPath: testDirPath))

    // Create the archive first
    var archiveCommand = try Archive.parse([testDirPath, archivePath])
    archiveCommand.allowOverride = true
    archiveCommand.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: archivePath))

    // Extract to a different directory
    let extractDir = buildPath(folder: URL(string: tmpDir)!, filename: "extracted").path
    defer { try? FileManager.default.removeItem(atPath: extractDir) }

    var unarchiveCommand = try Unarchive.parse([archivePath, extractDir])
    unarchiveCommand.run()

    let tmpDirs = try FileManager.default.contentsOfDirectory(atPath: extractDir)
    #expect(tmpDirs.count == 1)
    let rootDir = tmpDirs[0]

    // Verify extraction
    #expect(FileManager.default.fileExists(atPath: extractDir))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/\(rootDir)/"))
}

@Test func unarchiveNestedDirectoryArchive() async throws {
    let tmpDir = try createTestStructure(components: [
        .directory(
            "Project",
            [
                .directory(
                    "Sources",
                    [
                        .file("main.swift"),
                        .file("utils.swift"),
                    ]),
                .directory(
                    "Tests",
                    [
                        .file("test1.swift")
                    ]),
                .file("README.md"),
            ])
    ])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, filename: "Project").path
    let archivePath = buildPath(folder: URL(string: tmpDir)!, filename: "nested.tar").path
    defer { try? FileManager.default.removeItem(atPath: archivePath) }

    // Create the archive first
    var archiveCommand = try Archive.parse([testDirPath, archivePath])
    archiveCommand.allowOverride = true
    archiveCommand.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: archivePath))

    // Extract to a different directory
    let extractDir = buildPath(folder: URL(string: tmpDir)!, filename: "extracted").path
    defer { try? FileManager.default.removeItem(atPath: extractDir) }

    var unarchiveCommand = try Unarchive.parse([archivePath, extractDir])
    unarchiveCommand.run()

    // Verify root extraction directory exists
    #expect(FileManager.default.fileExists(atPath: extractDir))

    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/Project/"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/Project/Sources/"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/Project/Tests/"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/Project/Sources/main.swift"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/Project/Sources/utils.swift"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/Project/Tests/test1.swift"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/Project/README.md"))
}

@Test func unarchiveArchiveWithSpecialCharacters() async throws {
    let tmpDir = try createTestStructure(components: [
        .directory(
            "My Folder",
            [
                .file("file with spaces.txt"),
                .file("file with emoji 🎉.txt"),
                .file("normal.txt"),
            ])
    ])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, filename: "My Folder").path
    let archivePath = buildPath(folder: URL(string: tmpDir)!, filename: "special.tar").path
    defer { try? FileManager.default.removeItem(atPath: archivePath) }

    // Create the archive first
    var archiveCommand = try Archive.parse([testDirPath, archivePath])
    archiveCommand.allowOverride = true
    archiveCommand.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: archivePath))

    // Extract to a different directory
    let extractDir = buildPath(folder: URL(string: tmpDir)!, filename: "extracted").path
    defer { try? FileManager.default.removeItem(atPath: extractDir) }

    var unarchiveCommand = try Unarchive.parse([archivePath, extractDir])
    unarchiveCommand.run()

    // Verify extraction directory exists
    #expect(FileManager.default.fileExists(atPath: extractDir))

    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/My Folder/"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/My Folder/file with spaces.txt"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/My Folder/file with emoji 🎉.txt"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/My Folder/normal.txt"))
}

@Test func unarchiveNonExistentArchive() async throws {
    let tmpDir = try createTestStructure(components: [])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let nonExistentArchive = buildPath(folder: URL(string: tmpDir)!, filename: "does-not-exist.tar")
        .path
    let extractDir = buildPath(folder: URL(string: tmpDir)!, filename: "extracted").path

    // Verify archive does not exist
    #expect(!FileManager.default.fileExists(atPath: nonExistentArchive))

    var unarchiveCommand = try Unarchive.parse([nonExistentArchive, extractDir])
    unarchiveCommand.run()
}

@Test func unarchiveRawMode() async throws {
    let tmpDir = try createTestStructure(components: [
        .directory(
            "RawTest",
            [
                .file("test.txt")
            ])
    ])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, filename: "RawTest").path
    let archivePath = buildPath(folder: URL(string: tmpDir)!, filename: "raw.tar").path
    defer { try? FileManager.default.removeItem(atPath: archivePath) }

    // Create the archive first
    var archiveCommand = try Archive.parse([testDirPath, archivePath])
    archiveCommand.allowOverride = true
    archiveCommand.run()

    // Extract using raw mode
    let extractDir = buildPath(folder: URL(string: tmpDir)!, filename: "extracted-raw").path
    defer { try? FileManager.default.removeItem(atPath: extractDir) }

    var unarchiveCommand = try Unarchive.parse([
        archivePath,
        extractDir,
        "--unarchiver-mode", "raw",
    ])
    unarchiveCommand.run()

    // Verify extraction
    #expect(FileManager.default.fileExists(atPath: extractDir))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/RawTest/"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/RawTest/test.txt"))
}

@Test func unarchiveStreamingMode() async throws {
    let tmpDir = try createTestStructure(components: [
        .directory(
            "StreamingTest",
            [
                .file("test.txt")
            ])
    ])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, filename: "StreamingTest").path
    let archivePath = buildPath(folder: URL(string: tmpDir)!, filename: "streaming.tar").path
    defer { try? FileManager.default.removeItem(atPath: archivePath) }

    // Create the archive first
    var archiveCommand = try Archive.parse([testDirPath, archivePath])
    archiveCommand.allowOverride = true
    archiveCommand.run()

    // Extract using streaming mode
    let extractDir = buildPath(folder: URL(string: tmpDir)!, filename: "extracted-streaming").path
    defer { try? FileManager.default.removeItem(atPath: extractDir) }

    var unarchiveCommand = try Unarchive.parse([
        archivePath,
        extractDir,
        "--unarchiver-mode", "streaming",
    ])
    unarchiveCommand.run()

    // Verify extraction
    #expect(FileManager.default.fileExists(atPath: extractDir))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/StreamingTest/"))
    #expect(FileManager.default.fileExists(atPath: "\(extractDir)/StreamingTest/test.txt"))
}
