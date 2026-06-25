import Foundation
import Tar
import Testing

@testable import tsar

// MARK: - Archive Command Tests

@Test func doNotArchiveAFileOnly() async throws {
    let tmpDir = try createTestStructure(components: [.file("test.txt")])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testFilePath = buildPath(folder: URL(string: tmpDir)!, filename: "text.txt").path
    let outputPath = buildPath(folder: URL(string: tmpDir)!, filename: "output.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputPath) }

    var command = try Archive.parse([testFilePath, outputPath])
    command.run()

    // Verify archive was created
    #expect(!FileManager.default.fileExists(atPath: outputPath))
}

@Test func archiveADirectory() async throws {
    let tmpDir = try createTestStructure(components: [.directory("test_dir", [.file("test.txt")])])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, filename: "test_dir").path
    let outputPath = buildPath(folder: URL(string: tmpDir)!, filename: "output.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputPath) }

    var command = try Archive.parse([testDirPath, outputPath])
    command.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: outputPath))

    // Verify archive contents
    let archive = Tar.Archive(data: Array(try Data(contentsOf: URL(fileURLWithPath: outputPath))))
    let entries = Array(archive)
    #expect(entries.count == 1)
    #expect(entries[0].fields.path().hasSuffix("test_dir/test.txt"))
}

@Test func archiveDirectoryWithFiles() async throws {
    let tmpDir = try createTestStructure(components: [
        .directory(
            "MyApp",
            [
                .file("main.swift"),
                .file("README.md"),
            ])
    ])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, filename: "MyApp").path
    let outputPath = buildPath(folder: URL(string: tmpDir)!, filename: "output.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputPath) }

    var command = try Archive.parse([testDirPath, outputPath])
    command.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: outputPath))

    // Verify archive contains both files with directory structure
    let archive = Tar.Archive(data: Array(try Data(contentsOf: URL(fileURLWithPath: outputPath))))
    let paths = Array(archive).map { $0.fields.path() }

    for path in paths {
        #expect(path.hasSuffix("MyApp/main.swift") || path.hasSuffix("MyApp/README.md"))
    }
}

@Test func archiveNestedDirectoryStructure() async throws {
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
    let outputPath = buildPath(folder: URL(string: tmpDir)!, filename: "nested.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputPath) }

    var command = try Archive.parse([testDirPath, outputPath])
    command.run()

    // Verify nested structure is preserved
    let archive = Tar.Archive(data: Array(try Data(contentsOf: URL(fileURLWithPath: outputPath))))
    let paths = Array(archive).map { $0.fields.path() }

    for path in paths {
        #expect(
            path.hasSuffix("Project/Sources/main.swift")
                || path.hasSuffix("Project/Sources/utils.swift")
                || path.hasSuffix("Project/Tests/test1.swift")
                || path.hasSuffix("Project/README.md") || path.hasSuffix("Project/")
                || path.hasSuffix("Project/Sources/") || path.hasSuffix("Project/Tests/")
        )
    }
}
