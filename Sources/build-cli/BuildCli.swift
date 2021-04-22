import ArgumentParser
import Foundation
import URLFileManager
import BuildSystem
import Packages

@main
struct BuildCli: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [
      Build.self,
      BuildAll.self,
      NewPackage.self,
      CheckUpdate.self,
    ])
  }
}
