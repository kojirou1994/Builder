import ArgumentParser
import Foundation
import URLFileManager
import BuildSystem

struct BuildCli: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [
      Build.self,
      BuildAll.self
    ])
  }
}

BuildCli.main()
