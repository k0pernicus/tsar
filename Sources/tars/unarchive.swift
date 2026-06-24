import ArgumentParser
import Foundation
import Tar

struct Unarchive: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "Decompress an archive.")

    enum UnarchiverMode: String, ExpressibleByArgument {
        case streaming, raw
    }

    @Argument(help: "The path of the document to unarchive.")
    var archivePath: String

    @Argument(help: "The output path to uncompress the archive and store the result.")
    var outputPath: String

    @Option(help: "The kind of unarchiver to use (raw, streaming).")
    var unarchiverMode: UnarchiverMode = .raw

    @Option(
        help: "Active verbose output.")
    var verbose: Bool = false

    mutating func run() {
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
        guard let data = readFileAsBytes(atPath: self.archivePath) else {
            print("Error: cannot read the archive as bytes.")
            return
        }

        switch self.unarchiverMode {
        case .raw:
            let archive = Tar.Archive(data: data)
            do {
                let _ = try Tar.TarExtractor().extract(archive, to: self.outputPath)
                return
            } catch {
                print("Error: cannot extract content from archive.")
                return
            }
        case .streaming:
            // TODO
            print("Error: non implemented behaviour.")
            return
        }

    }

}
