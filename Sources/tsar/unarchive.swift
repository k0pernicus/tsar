import ArgumentParser
import Foundation
import Tar

struct Unarchive: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unarchive",
        abstract: "Extract files from a tar archive.")

    enum UnarchiverMode: String, ExpressibleByArgument {
        case streaming, raw
    }

    @Argument(help: "The path to the archive file.")
    var archivePath: String

    @Argument(help: "Output directory for extracted files.")
    var outputPath: String

    @Option(
        name: [.customShort("m"), .customLong("unarchiver-mode")],
        help: "Extraction mode (raw or streaming).")
    var unarchiverMode: UnarchiverMode = .raw

    @Flag(name: .shortAndLong, help: "Enable verbose output.")
    var verbose: Bool = false

    mutating func run() {
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

        switch self.unarchiverMode {
        case .raw:
            guard let data = readFileAsBytes(atPath: self.archivePath) else {
                print(FileError.FileOperation(archivePath))
                return
            }

            let archive = Tar.Archive(data: data)
            do {
                let _ = try Tar.TarExtractor().extract(archive, to: self.outputPath)
                return
            } catch {
                print(FileError.FileOperation(archivePath))
                return
            }
        case .streaming:
            var reader = Tar.TarReader()
            do {
                var extractor = try Tar.TarExtractor().streamingExtractor(to: self.outputPath)
                let fileHandle = try FileHandle(
                    forReadingFrom: URL(fileURLWithPath: self.archivePath))
                defer { fileHandle.closeFile() }

                let chunkSize: Int = 8192

                while true {
                    let chunkData = fileHandle.readData(ofLength: chunkSize)
                    guard !chunkData.isEmpty else { break }
                    let chunk = Array(chunkData)
                    let events = try reader.append(chunk)
                    try extractor.consume(events)
                }

                try extractor.consume(reader.finish())
                let _ = try extractor.finish()
            } catch {
                print(FileError.FileOperation(archivePath))
                return
            }
        }

    }

}
