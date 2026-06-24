import ArgumentParser
import Foundation
import Tar

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Lists an archive.")

    @Argument(help: "The path of the document to unarchive.")
    var archivePath: String

    mutating func run() throws {
        if archivePath.isEmpty {
            print("Error: please provide the path to a valid archive.")
            return
        }

        if !FileManager.default.fileExists(atPath: archivePath) {
            print("Error: archive not found.")
            return
        }
        guard FileManager.default.isReadableFile(atPath: self.archivePath) else {
            print("Error: archive is not readable.")
            return
        }

        guard let archiveContent = readFileAsBytes(atPath: self.archivePath) else {
            print("Error: cannot read the archive as bytes.")
            return
        }

        let archive = Tar.Archive(data: archiveContent)

        for entry in archive {
            let path = entry.fields.path()
            let size = entry.fields.size
            print("* \(path) (\(size) bytes)")
        }
    }
}
