// An error thrown by the CLI, during a command operation
enum FileError: Error, CustomStringConvertible {
    case FileNotFound(String)
    case FileOperation(String)
    case FolderNotFound(String)

    // Returns the error as a string
    var description: String {
        switch self {
        case .FileNotFound(let file): return "File with name '\(file)' not found"
        case .FileOperation(let file): return "Operation on file '\(file)' failed"
        case .FolderNotFound(let path): return "Folder with path '\(path)' not found"
        }
    }
}

enum UserError: Error, CustomStringConvertible {
    case IsNotADirectory(String)

    // Returns the error as a string
    var description: String {
        switch self {
        case .IsNotADirectory(let path): return "\(path) is not a directory."
        }
    }
}
