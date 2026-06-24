import ArgumentParser
import Foundation
import Tar

@main
struct Tsar: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility for building and extracting TAR archives",
        version: "0.1.0",
        subcommands: [Archive.self, Unarchive.self],
    )
}
