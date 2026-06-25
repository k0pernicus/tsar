import Foundation
import Tar

// Helper to get human-readable description of entry type
func entryTypeDescription(_ type: Tar.EntryType) -> String {
    switch type {
    case .regular: return "file"
    case .link: return "hard link"
    case .symlink: return "symlink"
    case .char: return "character device"
    case .block: return "block device"
    case .directory: return "directory"
    case .fifo: return "FIFO"
    case .continuous: return "continuous"
    case .gnuLongName: return "GNU long name"
    case .gnuLongLink: return "GNU long link"
    case .gnuSparse: return "GNU sparse"
    case .gnuVolumeLabel: return "GNU volume label"
    case .paxGlobalExtensions: return "PAX global extensions"
    case .paxLocalExtensions: return "PAX local extensions"
    case .other: return "other"
    }
}

func readFileAsBytes(atPath path: String) -> [UInt8]? {
    let fileURL = URL(fileURLWithPath: path)

    do {
        let data = try Data(contentsOf: fileURL)
        let bytes = Array(data)
        return bytes
    } catch {
        print("Error reading file: \(error.localizedDescription)")
        return nil
    }
}

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
