import ArgumentParser
import Foundation
import URLFileManager
import BuildSystem

let fm = URLFileManager.default

@main
struct Spm: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [
      Setup.self,
      Build.self,
    ])
  }
}
