import ArgumentParser
import Foundation
import Tar

struct Archive: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Compress a file or a folder as a tar file.")

    enum WriterMode: String, ExpressibleByArgument {
        case deterministic, complete
    }

    @Argument(help: "The path of the document to archive.")
    var documentPath: String

    @Argument(help: "The output path and name of the archive.")
    var outputPath: String

    @Option(help: "The kind of writer to use (complete, deterministic).")
    var writerMode: WriterMode = .deterministic

    @Option(help: "Continue archiving files and directories even if some files are missing.")
    var continueIfError: Bool = false

    @Option(help: "Skip archiving hidden files found in the folder (and subfolder).")
    var skipHiddenFiles: Bool = false

    @Option(
        help: "Allow override an existing archive, if the output path points to an existing file.")
    var allowOverride: Bool = false

    @Option(
        help: "Active verbose output.")
    var verbose: Bool = false

    func addFileToArchive(writer: inout Tar.TarWriter, filePath: String) -> Error? {
        if !FileManager.default.fileExists(atPath: filePath) {
            return FileError.FileNotFound(filePath)
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            let fileSize: UInt64 = attributes[.size] as! UInt64

            var fileHeader = Tar.Header(asGnu: ())
            fileHeader.setSize(fileSize)
            fileHeader.setMode(0o644)

            if let fileData = FileManager.default.contents(atPath: filePath) {
                writer.appendData(header: fileHeader, path: filePath, data: fileData)
                return nil
            } else {
                return FileError.FileNotFound(filePath)
            }
        } catch {
            return FileError.FileOperation(filePath)
        }
    }

    func addFolderToArchitect(writer: inout Tar.TarWriter, folderPath: String) {
        writer.appendDir(path: folderPath)
    }

    mutating func run() {

        if documentPath.isEmpty {
            print("Error: please provide the path to a valid document to archive.")
            return
        }

        if !FileManager.default.fileExists(atPath: documentPath) {
            print("Error: document not found.")
            return
        }

        var writer = Tar.TarWriter(
            mode: self.writerMode == WriterMode.deterministic ? .deterministic : .complete)

        let enumeratorOptions: FileManager.DirectoryEnumerationOptions =
            self.skipHiddenFiles ? [.skipsHiddenFiles] : []
        let enumerator = FileManager.default.enumerator(
            at: URL(string: self.documentPath)!, includingPropertiesForKeys: [],
            options: enumeratorOptions)

        while let url = enumerator?.nextObject() as? URL {
            do {
                let resourceValues = try url.resourceValues(forKeys: [
                    .isRegularFileKey, .isDirectoryKey,
                ])

                let resourcePath = url.path

                if resourceValues.isRegularFile ?? false {
                    if self.verbose { print(">> Found file: \(resourceValues)") }
                    if let err = addFileToArchive(
                        writer: &writer, filePath: resourcePath)
                    {
                        print(
                            "Error adding file \(resourceValues.canonicalPath!) to the archive: \(err)"
                        )
                        if self.continueIfError { continue } else { return }
                    }
                } else if resourceValues.isDirectory ?? false {
                    if self.verbose { print(">> Found directory: \(resourceValues)") }
                    if let resourcePath = resourceValues.path {
                        addFolderToArchitect(writer: &writer, folderPath: resourcePath)
                    }
                }
            } catch {
                print("Error: processing document to archive failed")
                return
            }
        }

        let archiveBytes = writer.finish()

        if !self.allowOverride {
            if FileManager.default.fileExists(atPath: self.outputPath) {
                print(
                    "Error: output already exists, do not have the permission to override (check CLI options to override"
                )
                return
            }
        }

        let data = Data.init(archiveBytes)
        FileManager.default.createFile(atPath: outputPath, contents: data)
    }
}
