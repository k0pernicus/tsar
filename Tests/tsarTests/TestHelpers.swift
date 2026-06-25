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

func createComponent(in folder: URL, component: FileArchitectureComponent) throws {
    switch component {
    case .none: return
    case .file(let filename):
        FileManager.default.createFile(
            atPath: buildPath(folder: folder, filename: filename).path,
            contents: generateTextForFile())
    case .directory(let directoryName, let subcomponents):
        for newComponent in subcomponents {
            try createComponent(
                in: buildPath(folder: folder, filename: directoryName), component: newComponent)
        }
    }
}

func createTestStructure(components: [FileArchitectureComponent]) throws -> String {
    let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

    for component in components {
        try createComponent(in: tmpDir, component: component)
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
