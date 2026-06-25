# tsar

A fast and pure-Swift command-line tool for creating and extracting TAR archives. 

 `tsar` is built on top of [**swift-tar**](https://github.com/kateinoigakukun/swift-tar).

---

## Features

- Create archives from directories
- Extract archives with full directory structure preservation
- Streaming support for memory-efficient handling of large files
- Cross-platform: macOS, Linux, Windows.
- No external dependencies beyond Swift standard library
- Supports both raw and deterministic writer modes

---

## Installation

### Using Swift Package Manager

```sh
# Clone the repository
git clone https://github.com/k0pernicus/tsar.git
cd tsar

# Build in debug mode (for development)
swift build -c debug

# Build in release mode (for production)
swift build -c release
```

The compiled binary will be at: `.build/debug/tsar` or `.build/release/tsar`

---

## Usage

### Archive a File or Directory

```sh
# Basic usage
tsar archive /path/to/source /path/to/output.tar

# With options
tsar archive source/ output.tar \
  --writer-mode deterministic \
  --skip-hidden-files \
  --verbose

# Short flags
tsar archive source/ output.tar -m deterministic -s -v
```

### Extract an Archive

```sh
# Basic usage
tsar unarchive input.tar /path/to/output

# With options
tsar unarchive input.tar output/ \
  --unarchiver-mode raw \
  --verbose

# Short flags
tsar unarchive input.tar output/ -m raw -v
```

### List Archive Contents

```sh
# List contents of an archive
tsar list archive.tar
```

---

## Examples

### Create an archive of a project
```sh
tsar archive ~/Projects/my-app/ my-app-backup.tar -s -v
```

### Extract to a specific directory
```sh
tsar unarchive backup.tar ~/Restored/ -m streaming
```

### Archive with custom mode
```sh
tsar archive source/ output.tar --writer-mode complete
```

---

## Troubleshooting

### Command not found
Make sure the binary is in your PATH or use the full path:
```sh
.build/release/tsar archive input/ output.tar
```

### Permission denied
Ensure you have read/write permissions for the source and destination paths.

---

## License

MIT License
