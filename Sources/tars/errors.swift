// An error thrown by the CLI, during a command operation
enum FileError: Error {
    case FileNotFound(String)
    case FileOperation(String)
    case FolderNotFound(String)
}
