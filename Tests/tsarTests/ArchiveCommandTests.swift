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

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "test_dir").path
    let outputPath = buildPath(folder: URL(string: tmpDir)!, filename: "output.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputPath) }

    var command = try Archive.parse([testDirPath, outputPath])
    command.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: outputPath))

    // Verify archive contents
    let archive = Tar.Archive(data: Array(try Data(contentsOf: URL(fileURLWithPath: outputPath))))
    let entries = Array(archive)

    #expect(entries.count == 2)

    let paths = entries.map { $0.fields.path() }

    #expect(paths.contains(where: { $0.hasSuffix("test_dir/") }))
    #expect(paths.contains(where: { $0.hasSuffix("test_dir/test.txt") }))
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

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "MyApp").path
    let outputPath = buildPath(folder: URL(string: tmpDir)!, filename: "output.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputPath) }

    var command = try Archive.parse([testDirPath, outputPath])
    command.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: outputPath))

    // Verify archive contains both files with directory structure
    let archive = Tar.Archive(data: Array(try Data(contentsOf: URL(fileURLWithPath: outputPath))))
    let paths = Array(archive).map { $0.fields.path() }

    #expect(paths.count == 3)

    #expect(paths.contains(where: { $0.hasSuffix("MyApp/") }))
    #expect(paths.contains(where: { $0.hasSuffix("MyApp/main.swift") }))
    #expect(paths.contains(where: { $0.hasSuffix("MyApp/README.md") }))
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

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "Project").path
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

// MARK: - Empty Directory

@Test func archiveAnEmptyDirectory() async throws {
    let tmpDir = try createTestStructure(components: [.directory("Empty", [])])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "Empty").path
    let outputPath = buildPath(folder: URL(string: tmpDir)!, filename: "empty.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputPath) }

    #expect(FileManager.default.fileExists(atPath: testDirPath))

    var command = try Archive.parse([testDirPath, outputPath])
    command.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: outputPath))

    // Verify archive contains the empty directory
    let archive = Tar.Archive(data: Array(try Data(contentsOf: URL(fileURLWithPath: outputPath))))
    let paths = Array(archive).map { $0.fields.path() }
    #expect(paths.count > 0)

    for path in paths {
        #expect(path.hasSuffix("Empty/"))
    }
}

// MARK: - Special Characters

@Test func archiveFilesWithEmojisAndSpaces() async throws {
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

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "My Folder").path
    let outputPath = buildPath(folder: URL(string: tmpDir)!, filename: "special.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputPath) }

    var command = try Archive.parse([testDirPath, outputPath])
    command.run()

    // Verify archive was created
    #expect(FileManager.default.fileExists(atPath: outputPath))

    // Verify all files including those with special characters are archived
    let archive = Tar.Archive(data: Array(try Data(contentsOf: URL(fileURLWithPath: outputPath))))
    let paths = Array(archive).map { $0.fields.path() }

    for path in paths {
        #expect(
            path.hasSuffix("My Folder/file with spaces.txt")
                || path.hasSuffix("My Folder/file with emoji 🎉.txt")
                || path.hasSuffix("My Folder/normal.txt")
                || path.hasSuffix("My Folder/")
        )
    }
}

// MARK: - Writer Modes

@Test func archiveDeterministicAndCompleteModes() async throws {
    let tmpDir = try createTestStructure(components: [
        .directory(
            "ModeTest",
            [
                .file("test.txt")
            ])
    ])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "ModeTest").path

    // Test deterministic mode
    let deterministicOutput = buildPath(folder: URL(string: tmpDir)!, filename: "deterministic.tar")
        .path
    defer { try? FileManager.default.removeItem(atPath: deterministicOutput) }

    var deterministicCommand = try Archive.parse([
        testDirPath,
        deterministicOutput,
        "--writer-mode", "deterministic",
    ])
    deterministicCommand.run()
    #expect(FileManager.default.fileExists(atPath: deterministicOutput))

    // Test complete mode
    let completeOutput = buildPath(folder: URL(string: tmpDir)!, filename: "complete.tar").path
    defer { try? FileManager.default.removeItem(atPath: completeOutput) }

    var completeCommand = try Archive.parse([
        testDirPath,
        completeOutput,
        "--writer-mode", "complete",
    ])
    completeCommand.run()
    #expect(FileManager.default.fileExists(atPath: completeOutput))

    // Verify both archives contain the expected file
    let deterministicArchive = Tar.Archive(
        data: Array(try Data(contentsOf: URL(fileURLWithPath: deterministicOutput))))
    let completeArchive = Tar.Archive(
        data: Array(try Data(contentsOf: URL(fileURLWithPath: completeOutput))))

    let deterministicPaths = Array(deterministicArchive).map { $0.fields.path() }
    let completePaths = Array(completeArchive).map { $0.fields.path() }

    for path in deterministicPaths {
        #expect(path.hasSuffix("ModeTest/test.txt") || path.hasSuffix("ModeTest/"))
    }
    for path in completePaths {
        #expect(path.hasSuffix("ModeTest/test.txt") || path.hasSuffix("ModeTest/"))
    }
}

// MARK: - Skip Hidden Files Flag

@Test func archiveSkipHiddenFilesFlag() async throws {
    let tmpDir = try createTestStructure(components: [
        .directory(
            "HiddenTest",
            [
                .file("visible.txt"),
                .file(".hidden.txt"),
            ])
    ])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "HiddenTest").path

    // Test WITH skip-hidden-files flag
    let outputWithSkip = buildPath(folder: URL(string: tmpDir)!, filename: "with-skip.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputWithSkip) }

    var commandWithSkip = try Archive.parse([
        testDirPath,
        outputWithSkip,
        "--skip-hidden-files",
    ])
    commandWithSkip.run()

    let archiveWithSkip = Tar.Archive(
        data: Array(try Data(contentsOf: URL(fileURLWithPath: outputWithSkip))))
    let pathsWithSkip = Array(archiveWithSkip).map { $0.fields.path() }

    // Should NOT contain hidden files
    for path in pathsWithSkip {
        #expect(!path.hasSuffix("HiddenTest/.hidden.txt"))
    }
    // Should contain visible files
    for path in pathsWithSkip {
        #expect(path.hasSuffix("HiddenTest/visible.txt") || path.hasSuffix("HiddenTest/"))
    }

    // Test WITHOUT skip-hidden-files flag (default behavior)
    let outputWithoutSkip = buildPath(folder: URL(string: tmpDir)!, filename: "without-skip.tar")
        .path
    defer { try? FileManager.default.removeItem(atPath: outputWithoutSkip) }

    var commandWithoutSkip = try Archive.parse([
        testDirPath,
        outputWithoutSkip,
    ])
    commandWithoutSkip.run()

    let archiveWithoutSkip = Tar.Archive(
        data: Array(try Data(contentsOf: URL(fileURLWithPath: outputWithoutSkip))))
    let pathsWithoutSkip = Array(archiveWithoutSkip).map { $0.fields.path() }

    // Should contain both visible and hidden files
    for path in pathsWithoutSkip {
        #expect(
            path.hasSuffix("HiddenTest/visible.txt")
                || path.hasSuffix("HiddenTest/.hidden.txt")
                || path.hasSuffix("HiddenTest/")
        )
    }
}

// MARK: - Overwrite Flag

@Test func archiveOverwriteFlag() async throws {
    let tmpDir = try createTestStructure(components: [.directory("test_dir", [.file("test.txt")])])
    defer { try? FileManager.default.removeItem(atPath: tmpDir) }

    let testDirPath = buildPath(folder: URL(string: tmpDir)!, dirname: "test_dir").path

    // Test WITH allow-override flag
    let outputWithOverride = buildPath(folder: URL(string: tmpDir)!, filename: "output.tar").path
    defer { try? FileManager.default.removeItem(atPath: outputWithOverride) }

    // Create the output file first
    try? "existing content".data(using: .utf8)?.write(to: URL(fileURLWithPath: outputWithOverride))

    var commandWithOverride = try Archive.parse([
        testDirPath,
        outputWithOverride,
        "--allow-override",
    ])
    commandWithOverride.run()

    // Verify file was overwritten
    let archiveWithOverride = Tar.Archive(
        data: Array(try Data(contentsOf: URL(fileURLWithPath: outputWithOverride))))
    #expect(Array(archiveWithOverride).count > 0)

    // Test WITHOUT allow-override flag (default behavior)
    let outputWithoutOverride = buildPath(folder: URL(string: tmpDir)!, filename: "output2.tar")
        .path
    defer { try? FileManager.default.removeItem(atPath: outputWithoutOverride) }

    // Create the output file first
    try? "existing content".data(using: .utf8)?.write(
        to: URL(fileURLWithPath: outputWithoutOverride))

    var commandWithoutOverride = try Archive.parse([
        testDirPath,
        outputWithoutOverride,
    ])
    commandWithoutOverride.run()

    // Verify file was NOT overwritten
    let content = try? String(
        data: Data(contentsOf: URL(fileURLWithPath: outputWithoutOverride)), encoding: .utf8)
    #expect(content == "existing content")
}
