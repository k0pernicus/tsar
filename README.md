# Tars

Tars is a CLI command that compresses and uncompresses tar files.  
This tool uses the [swift-tar](https://github.com/kateinoigakukun/swift-tar) library as a backend.

## Build

The project uses the swift package manager by default.

You can build a debug version for debugging and testing purposes:

```
swift build -c debug
```

or a release one for maximum performances (does not contain debug symbols):

```
swift build -c release
```

## Usage

### Archive

```sh
tars archive --help # to get help for archive subcommand
tars archive <INPUT_FOLDER> <OUTPUT_PATH/OUTPUT_FILE>
```

### Unarchive

```sh
tars unarchive --help # to get help for unarchive subcommand
tars unarchive <ARCHIVE_FILE> <OUTPUT_PATH>
```

## License

MIT License
