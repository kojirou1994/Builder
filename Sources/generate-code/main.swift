import Foundation
import URLFileManager

func ident(_ count: Int) -> String {
  .init(repeating: " " as Character, count: count * 2)
}

enum BuildCliCommand: CaseIterable {
  case build
  case buildAll

  var commandName: String {
    switch self {
    case .build: return "Build"
    case .buildAll: return "BuildAll"
    }
  }

  var subcommandName: String {
    switch self {
    case .build: return "PackageBuildCommand"
    case .buildAll: return "PackageBuildAllCommand"
    }
  }

  func generate(packageNames: [String], outputDirectory: URL) throws {
    let code = """
    import BuildSystem

    struct \(commandName): ParsableCommand {
      static var configuration: CommandConfiguration {
        .init(subcommands: [
    \(packageNames.map { ident(3) + "\(subcommandName)<\($0)>.self," }.joined(separator: "\n"))
        ])
      } // end of configuration
    } // end of \(commandName)
    """

    try code.write(to: outputDirectory.appendingPathComponent(commandName).appendingPathExtension("swift"), atomically: true, encoding: .utf8)
  }
}

let sourceDirectory = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .appendingPathComponent("build-cli")

let packageDirectory = sourceDirectory
  .appendingPathComponent("packages")

let fm = URLFileManager.default

let packageNames = try fm.contentsOfDirectory(at: packageDirectory)
  .map { $0.lastPathComponent}
  .filter { $0.hasSuffix(".swift") }
  .map { String($0.dropLast(6)) }
  .sorted()

try BuildCliCommand.allCases.forEach { cmd in
  try cmd.generate(packageNames: packageNames, outputDirectory: sourceDirectory)
}

let testAllPackagesFileURL =
  URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent() // target
  .deletingLastPathComponent() // source
  .deletingLastPathComponent() //package
  .appendingPathComponent("Tests/BuilderSystemTests/AllPackages.swift")

try """
@testable import build_cli
import BuildSystem

let packages: [Package.Type] = [
\(packageNames.map {"\($0).self,"}.joined(separator: "\n"))
]
"""
  .write(to: testAllPackagesFileURL, atomically: true, encoding: .utf8)
