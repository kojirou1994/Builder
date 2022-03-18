import ArgumentParser
import ExecutableLauncher
import Foundation
import KwiftExtension
import URLFileManager
import XcodeExecutable
import BuildSystem
import Precondition
import Logging
import JSON

extension TargetSystem {
  var spmString: String {
    switch self {
    case .macOS:
      return "macosx"
    case .linuxGNU:
      return "linux"
    default:
      fatalError()
    }
  }
}

extension TargetTriple {
  var spmString: String {
    "\(arch.clangTripleString)-\(system.vendor)-\(system.spmString)"
  }
}

enum SwiftCommand {
  static let dumpPackage = AnyExecutable(executableName: "swift", arguments: ["package", "dump-package"])
  static let describe = AnyExecutable(executableName: "swift", arguments: ["package", "describe", "--type", "json"])
  static let clean = AnyExecutable(executableName: "swift", arguments: ["package", "clean"])
}

struct SwiftBuild: Executable {
  static let executableName = "swift"

  let configuration: String
  let arch: TargetArch
  let buildPath: String
  let extraArguments: [String]

  var arguments: [String] {
    var arg = ["build"]

    arg.append(contentsOf: ["-c", configuration])
    arg.append(contentsOf: ["--build-path", buildPath])
    arg.append(contentsOf: ["--arch", arch.clangTripleString])

    #if !canImport(Darwin)
    arg.append("--enable-test-discovery")
    #endif

    arg.append(contentsOf: extraArguments)
    return arg
  }
}

struct Build: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(abstract: "Build spm products")
  }

  @Flag(name: .shortAndLong, help: "Strip built binaries")
  var strip: Bool = false

  @Flag(help: "Clean before building")
  var clean: Bool = false

  @Flag(name: .shortAndLong, help: "Debug mode")
  var debug: Bool = false

  @Flag(name: .shortAndLong, help: "Install exported products only")
  var exported: Bool = false

  @Flag(name: .shortAndLong, help: "Verbose mode")
  var verbose: Bool = false

  @Option(help: "Install prefix")
  var prefix: String?

  @Option(name: .customLong("arch"), help: ArgumentHelp(valueName: "arch"))
  var archs: [TargetArch] = [.native]

  @Argument(help: ArgumentHelp(valueName: "argument"))
  var extraArguments: [String] = []

  func validate() throws {
    try preconditionOrThrow(!archs.isEmpty, "No arch!")
  }

  func run() throws {

    let logger = Logger(label: "build")
    let launcher = TSCExecutableLauncher(outputRedirection: verbose ? .none : .stream(stdout: { _ in
    }, stderr: { _ in
    }))

    let installDirectoryURL = prefix.map { URL(fileURLWithPath: $0) }

    try installDirectoryURL.map { url in
      switch fm.fileExistance(at: url) {
      case .directory:
        break
      case .file:
        throw ValidationError("install prefix \(prefix!) is a file!")
      case .none:
        try fm.createDirectory(at: url)
      }
    }

    let spmBinaryDirectoryURL = try getBuildPath(logger: logger, archs: archs, prefix: "bin", rootPath: nil)
    try? fm.removeItem(at: spmBinaryDirectoryURL)
    try fm.createDirectory(at: spmBinaryDirectoryURL)

    let binaryNames: [String]

    do {
      let result = try SwiftCommand.dumpPackage
        .launch(use: TSCExecutableLauncher())

      let json = try JSON.read(result.output.get())
      if exported {
        binaryNames = json.root["products"]!.array!.compactMap { product in
          if product["type"]!["executable"] != nil {
            return product["name"]!.string!
          }
          return nil
        }
      } else {
        binaryNames = json.root["targets"]!.array!.compactMap { product in
          if product["type"]!.string == "executable" {
            return product["name"]!.string!
          }
          return nil
        }
      }

    }

    let configuration = debug ? "debug" : "release"
    var archBinPaths = [URL]()

    for arch in Set(archs).sorted(by: \.rawValue) {
      logger.info("Building arch \(arch) with configuration: \(configuration)")
      let buildPath = try getBuildPath(logger: logger, archs: [arch], prefix: "build", rootPath: nil)

      let startDate = Date()
      try SwiftBuild(configuration: configuration, arch: arch, buildPath: buildPath.path, extraArguments: extraArguments)
        .launch(use: launcher)
      logger.info("Totally used: \(String(format: "%.3f", Date().timeIntervalSince(startDate))) seconds")

      // TODO: use --show-bin-path
      archBinPaths.append(buildPath.appendingPathComponent(configuration))
    }

    try binaryNames.forEach { name in
      let universalBinaryURL = spmBinaryDirectoryURL.appendingPathComponent(name)

      if archBinPaths.count == 1 {
        try fm.copyItem(at: archBinPaths[0].appendingPathComponent(name), to: universalBinaryURL)
      } else {
        let archBinaries = archBinPaths.map { $0.appendingPathComponent(name).path }
        logger.info("Creating universal binary for \(name), output: \(universalBinaryURL.path)")

        logger.info("Source files: \(archBinaries)")

        try Lipo(files: archBinaries, output: universalBinaryURL.path)
          .launch(use: launcher)
      }

      if strip {
        logger.info("Striping \(name)")
        try Strip(file: universalBinaryURL.path)
          .launch(use: launcher)
      }

      try installDirectoryURL.map { url in
        let dst = url.appendingPathComponent(name)
        if fm.fileExistance(at: dst).exists {
          logger.info("Removing installed file at \(dst.path)")
          try fm.removeItem(at: dst)
        }
        logger.info("Installing \(name) to \(dst.path)")
        try fm.copyItem(at: universalBinaryURL, to: dst)
      }
    }
  }
}
