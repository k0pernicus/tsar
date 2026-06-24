import ArgumentParser
import Foundation
import Tar

@main
struct Tars: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility to operate with tar files",
        version: "0.1.0",
        subcommands: [Archive.self, Unarchive.self],
    )
}
