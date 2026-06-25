import Foundation
import Logging
import Testing

enum FileArchitectureComponent {
    case file(String)
    case directory(String, [FileArchitectureComponent])
    case none
}

// Generate random text content for each file
func generateTextForFile() -> Data {
    let words = [
        "Lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit",
        "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore",
        "magna", "aliqua", "test", "data", "random", "content", "file", "archive",
    ]

    let wordCount = Int.random(in: 10...50)
    let randomWords = (0..<wordCount).map { _ in words.randomElement()! }
    let text = randomWords.joined(separator: " ") + "."

    return Data(text.utf8)
}

func buildPath(folder: URL, filename: String) -> URL {
    return folder.appendingPathComponent(filename)
}

func createComponent(in folder: URL, component: FileArchitectureComponent) throws -> URL {
    switch component {
    case .none:
        return folder
    case .file(let filename):
        let url = buildPath(folder: folder, filename: filename)
        let _ = FileManager.default.createFile(
            atPath: url.path,
            contents: generateTextForFile())
        return url
    case .directory(let directoryName, let subcomponents):
        let subpath = buildPath(folder: folder, filename: directoryName)
        try FileManager.default.createDirectory(
            at: subpath,
            withIntermediateDirectories: true)
        for newComponent in subcomponents {
            let _ = try createComponent(in: subpath, component: newComponent)
        }
        return subpath
    }
}

func createTestStructure(components: [FileArchitectureComponent]) throws -> String {
    let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

    for component in components {
        let _ = try createComponent(in: tmpDir, component: component)
    }

    return tmpDir.path
}

// Initialize the logger dynamically based on the environment
func getlogger(label: String = "com.k0pernicus.tsar.tests") -> Logger {
    var log = Logger(label: label)

    if let env = ProcessInfo.processInfo.environment["LOG_LEVEL"],
        let level = Logger.Level(rawValue: env.lowercased())
    {
        log.logLevel = level
    } else {
        log.logLevel = .info
    }

    return log
}

// MARK - Empty directory

// Test of the helpers
@Test("empty directory")
func emptyDirectory() throws {
    do {
        let tmpDir = try createTestStructure(components: [])
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        // temporary folder exists...
        assert(FileManager.default.fileExists(atPath: tmpDir))
        // but it does not contain anything
        let dirContent = try FileManager.default.contentsOfDirectory(atPath: tmpDir)
        assert(dirContent.isEmpty)
    } catch {
        throw error
    }
}

// MARK - None should not create any directory

@Test("none does not create any directory")
func noneCheckDirectory() throws {
    do {
        let tmpDir = try createTestStructure(components: [.none])
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        // temporary folder exists...
        assert(FileManager.default.fileExists(atPath: tmpDir))

        let dirContent = try FileManager.default.contentsOfDirectory(atPath: tmpDir)
        assert(dirContent.isEmpty)
    } catch {
        throw error
    }
}

// MARK - One file in directory can be archived

@Test("one file in directory")
func oneDocumentCreation() throws {
    do {
        let filename = "example.txt"
        let tmpDir = try createTestStructure(components: [.file(filename)])
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        // temporary folder exists...
        assert(FileManager.default.fileExists(atPath: tmpDir))

        let dirContent = try FileManager.default.contentsOfDirectory(atPath: tmpDir)
        assert(!dirContent.isEmpty)
        assert(dirContent.count == 1)
        assert(dirContent[0] == filename)
    } catch {
        throw error
    }
}

// MARK - One empty directory is, by default, a directory itself

@Test("one empty directory in directory")
func oneEmptyDirectoryCreation() throws {
    do {
        let dirname = "example_dir"
        let tmpDir = try createTestStructure(components: [.directory(dirname, [.none])])
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        // temporary folder exists...
        assert(FileManager.default.fileExists(atPath: tmpDir))

        let dirContent = try FileManager.default.contentsOfDirectory(atPath: tmpDir)
        assert(!dirContent.isEmpty)
        assert(dirContent.count == 1)
        assert(dirContent[0] == dirname)
    } catch {
        throw error
    }
}

// MARK - Check for building complex structures

@Test("complex structure in directory")
func complexStructureInDirectoryCreation() throws {
    do {
        let dirname = "example_dir"
        let filenameInDir = "example.txt"
        let tmpDir = try createTestStructure(components: [
            .directory(dirname, [.file(filenameInDir), .none])
        ])
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        assert(FileManager.default.fileExists(atPath: tmpDir))

        let dirContent = try FileManager.default.contentsOfDirectory(atPath: tmpDir)
        assert(!dirContent.isEmpty)
        assert(dirContent.count == 1)
        assert(dirContent[0] == dirname)

        let subdirPath = buildPath(folder: URL(string: tmpDir)!, filename: dirname)
        let subdirContent = try FileManager.default.contentsOfDirectory(
            atPath: subdirPath.path)
        assert(!subdirContent.isEmpty)
        assert(subdirContent.count == 1)
        assert(subdirContent[0] == filenameInDir)
    } catch {
        throw error
    }
}
