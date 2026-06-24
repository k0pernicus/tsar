import ArgumentParser
import Foundation
import Tar

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List contents of a tar archive.")

    @Argument(help: "The path to the archive file.")
    var archivePath: String

    mutating func run() throws {
        if archivePath.isEmpty {
            print("Error: please provide the path to a valid archive.")
            return
        }

        if !FileManager.default.fileExists(atPath: archivePath) {
            print(FileError.FileNotFound(archivePath))
            return
        }
        guard FileManager.default.isReadableFile(atPath: self.archivePath) else {
            print("Error: archive is not readable.")
            return
        }

        guard let archiveContent = readFileAsBytes(atPath: self.archivePath) else {
            print(FileError.FileOperation(archivePath))
            return
        }

        let archive = Tar.Archive(data: archiveContent)

        var totalBytes: UInt64 = 0
        var entryCount = 0

        for entry in archive {
            entryCount += 1
            let path = entry.fields.path()
            let size = entry.fields.size
            totalBytes += size
            let sizeString = ByteCountFormatter().string(fromByteCount: Int64(size))
            let typeDescription = entryTypeDescription(entry.fields.effectiveEntryType())
            print("* \(path) (\(sizeString), \(typeDescription))")
        }

        let totalString = ByteCountFormatter().string(fromByteCount: Int64(totalBytes))
        print("Total: \(totalString) in \(entryCount) entries")
    }
}
