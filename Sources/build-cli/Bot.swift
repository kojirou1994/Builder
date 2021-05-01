import ArgumentParser
import Foundation
import URLFileManager
import BuildSystem
import PackagesInfo

struct BotCheckUpdate: ParsableCommand {

  @Option
  var workPath = "."

  struct CheckSummary: Codable {
    let packageName: String
    let newVersions: [NewVersion]
    struct NewVersion: Codable {
//      let source: PackageSource
      let version: Version
      let buildSuccess: Bool
    }
  }

  struct FailedSummary: Codable {
    let packageName: String
    let error: String
  }

  struct Summary: Codable {
    var successed: [CheckSummary]
    var failed: [FailedSummary]
  }

  func run() throws {
    let checker = PackageUpdateChecker()
    var summary = Summary(successed: [], failed: [])
    allPackages.forEach { package in
      let name = package.name
      do {
        let newVersions = try checker.check(package: package.defaultPackage)
        if !newVersions.isEmpty {
          summary.successed.append(.init(packageName: name, newVersions: newVersions.map { .init(version: $0, buildSuccess: false) }))
        }
      } catch {
        summary.failed.append(.init(packageName: name, error: String(describing: error)))
      }
    }

    print("All Checked")
    print("Summary:")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
    print(try encoder.encode(summary).utf8String)
  }
}

struct TestBuild: ParsableCommand {

  @Option
  var workPath = "."

  func run() throws {

  }
}

struct Bot: ParsableCommand {

  static var configuration: CommandConfiguration {
    .init(subcommands: [
      BotCheckUpdate.self,
      TestBuild.self,
    ])
  }

}
