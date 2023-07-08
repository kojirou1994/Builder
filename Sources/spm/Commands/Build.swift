import ArgumentParser
import TSCExecutableLauncher
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
}

struct SwiftPM: Executable {
  static let executableName = "swift"

  enum Command {
    case build(showBinPath: Bool, staticLink: Bool)
    case clean
  }
  var command: Command
  let configuration: String
  let archs: [TargetArch]
  let buildPath: String?
  let extraArguments: [String]

  var arguments: [String] {
    var arg = [String]()
    switch command {
    case let .build(showBinPath, staticLink):
      arg.append("build")
      if showBinPath {
        arg.append("--show-bin-path")
      } else {
        #if os(Linux)
        if staticLink {
          arg.append("--static-swift-stdlib")
        }
        #endif
      }
    case .clean:
      arg.append("package")
      arg.append("clean")
    }

    arg.append(contentsOf: ["-c", configuration])
    if let buildPath {
      arg.append(contentsOf: ["--scratch-path", buildPath])
    }
    archs.forEach { arg.append(contentsOf: ["--arch", $0.clangTripleString]) }

    arg.append(contentsOf: extraArguments)
    return arg
  }
}

struct Build: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(abstract: "Build spm products")
  }

  @Flag(name: .customLong("static"), help: "Strip built binaries")
  var staticLink: Bool = false

  @Flag(name: .shortAndLong, help: "Strip built binaries")
  var strip: Bool = false

  @Flag(help: "Clean before building")
  var clean: Bool = false

  @Flag(name: .shortAndLong, help: "Debug mode")
  var debug: Bool = false

  @Flag(help: "Build universal directly, fast for one-time, slow for incremental")
  var directUniversal: Bool = false

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

      let json = try JSON.read(bytes: result.output.get()).get()
      if exported {
        binaryNames = json.root!["products"]!.array!.compactMap { product in
          if product["type"]!["executable"] != nil {
            return product["name"]!.string!
          }
          return nil
        }
      } else {
        binaryNames = json.root!["targets"]!.array!.compactMap { product in
          if product["type"]!.string == "executable" {
            return product["name"]!.string!
          }
          return nil
        }
      }

    }

    let configuration = debug ? "debug" : "release"

    func build(archs: [TargetArch], onlyBuildingNativeArch: Bool) throws -> URL {
      logger.info("Building arch \(archs.map(\.clangTripleString).joined(separator: "_")) with configuration: \(configuration)")
      let buildPath: String? = try onlyBuildingNativeArch ? nil : getBuildPath(logger: logger, archs: archs, prefix: "build", rootPath: nil).path

      var command = SwiftPM(command: .clean, configuration: configuration, archs: archs, buildPath: buildPath, extraArguments: extraArguments)

      if clean {
        logger.info("Cleaning")
        try command.launch(use: launcher)
      }

      command.command = .build(showBinPath: false, staticLink: staticLink)
      let startDate = Date()
      try command.launch(use: launcher)
      logger.info("Totally used: \(String(format: "%.3f", Date().timeIntervalSince(startDate))) seconds")

      command.command = .build(showBinPath: true, staticLink: staticLink)
      let binPath = try command.launch(use: TSCExecutableLauncher())
        .utf8Output().trimmingCharacters(in: .whitespacesAndNewlines)
      logger.info("bin path: \(binPath)")
      return URL(fileURLWithPath: binPath)
    }

    var archBinPaths = [URL]()

    let allArchs = Set(archs).sorted(by: \.rawValue)
    let onlyBuildingNativeArch = allArchs == [.native]
    if directUniversal {
      let binPath = try build(archs: allArchs, onlyBuildingNativeArch: onlyBuildingNativeArch)
      archBinPaths.append(binPath)
    } else {
      for arch in allArchs {
        let binPath = try build(archs: [arch], onlyBuildingNativeArch: onlyBuildingNativeArch)
        archBinPaths.append(binPath)
      }
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
