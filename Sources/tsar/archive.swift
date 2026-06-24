import ArgumentParser
import Foundation
import Tar

struct Archive: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "archive",
        abstract: "Compress a file or folder into a tar archive.")

    enum WriterMode: String, ExpressibleByArgument {
        case deterministic, complete
    }

    @Argument(help: "The path to the file or folder to archive.")
    var documentPath: String

    @Argument(help: "The output path and name of the archive.")
    var outputPath: String

    @Option(shortName: "m", help: "Writer mode (complete or deterministic).")
    var writerMode: WriterMode = .deterministic

    @Flag(shortName: "c", help: "Continue archiving entries even if some are missing.")
    var continueIfError: Bool = false

    @Flag(shortName: "s", help: "Skip archiving hidden files found in the folder (and subfolders).")
    var skipHiddenFiles: Bool = false

    @Flag(shortName: "f", help: "Override existing output file.")
    var allowOverride: Bool = false

    @Flag(shortName: "v", help: "Enable verbose output.")
    var verbose: Bool = false

    func addFileToArchive(writer: inout Tar.TarWriter, filePath: String, archivePath: String)
        -> Error?
    {
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
                writer.appendData(header: fileHeader, path: archivePath, data: fileData)
                return nil
            } else {
                return FileError.FileNotFound(filePath)
            }
        } catch {
            return FileError.FileOperation(filePath)
        }
    }

    func addFolderToArchive(writer: inout Tar.TarWriter, folderPath: String) {
        writer.appendDir(path: folderPath)
    }

    mutating func run() {

        if documentPath.isEmpty {
            print("Error: please provide the path to a valid document to archive.")
            return
        }

        if !FileManager.default.fileExists(atPath: documentPath) {
            print(FileError.FileNotFound(documentPath))
            return
        }

        var writer = Tar.TarWriter(
            mode: self.writerMode == WriterMode.deterministic ? .deterministic : .complete)

        let enumeratorOptions: FileManager.DirectoryEnumerationOptions =
            self.skipHiddenFiles ? [.skipsHiddenFiles] : []

        // Normalize documentPath: remove trailing slashes
        let documentURL = URL(fileURLWithPath: self.documentPath)
        var docPath = documentURL.path
        while docPath.hasSuffix("/") {
            docPath = String(docPath.dropLast())
        }
        let normalizedURL = URL(fileURLWithPath: docPath)

        // Calculate parent path to preserve the folder name in archive
        let parentURL = normalizedURL.deletingLastPathComponent()
        let parentPath = parentURL.path
        let parentPrefix =
            parentPath.isEmpty ? "" : (parentPath.hasSuffix("/") ? parentPath : parentPath + "/")

        let enumerator = FileManager.default.enumerator(
            at: normalizedURL,
            includingPropertiesForKeys: [],
            options: enumeratorOptions)

        while let url = enumerator?.nextObject() as? URL {
            do {
                let resourceValues = try url.resourceValues(forKeys: [
                    .isRegularFileKey, .isDirectoryKey,
                ])

                let resourcePath = url.path
                // Strip parent prefix to preserve folder name (e.g., archive X/ -> X/file.txt, not file.txt)
                let relativePath =
                    parentPrefix.isEmpty
                    ? resourcePath : String(resourcePath.dropFirst(parentPrefix.count))

                if resourceValues.isRegularFile ?? false {
                    if self.verbose { print(">> Found file: \(resourceValues)") }
                    if let err = addFileToArchive(
                        writer: &writer, filePath: resourcePath, archivePath: relativePath)
                    {
                        print(err)
                        if self.continueIfError { continue } else { return }
                    }
                } else if resourceValues.isDirectory ?? false {
                    if self.verbose { print(">> Found directory: \(resourceValues)") }
                    addFolderToArchive(writer: &writer, folderPath: relativePath)
                }
            } catch {
                print(FileError.FileOperation(docPath))
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
