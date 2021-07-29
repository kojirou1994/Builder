import ArgumentParser
import ExecutableLauncher
import Foundation
import KwiftExtension
import URLFileManager
import XcodeExecutable
import BuildSystem

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
  static let describe = AnyExecutable(executableName: "swift", arguments: ["package", "describe", "--type", "json"])
  static let update = AnyExecutable(executableName: "swift", arguments: ["package", "update"])
}

struct SwiftBuild: Executable {
  static let executableName = "swift"

  let debug: Bool
  let integrated: Bool
  let arch: TargetArch
  let extraArguments: [String]

  var arguments: [String] {
    var arg = ["build"]
    if !debug {
      arg.append(contentsOf: ["-c", "release"])
    }
    if integrated {
      arg.append("--use-integrated-swift-driver")
    }
    arg.append(contentsOf: ["--arch", arch.clangTripleString])
    #if !canImport(Darwin)
    arg.append("--enable-test-discovery")
    #endif

    arg.append(contentsOf: extraArguments)
    return arg
  }
}

let spmProductDir = "spm_binaries"

struct Build: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(abstract: "Build spm products")
  }

  @Flag(name: .shortAndLong, help: "Use integrated swift driver")
  var integrated: Bool = false

  @Flag(name: .shortAndLong, help: "Strip built binaries")
  var strip: Bool = false

  @Flag(name: .shortAndLong, help: "Update before building")
  var update: Bool = false

  @Flag(name: .shortAndLong, help: "Debug mode")
  var debug: Bool = false

  @Flag(name: .shortAndLong, help: "Exported executable only")
  var exported: Bool = false

  @Flag(name: .shortAndLong, help: "Verbose mode")
  var verbose: Bool = false

  @Option(name: .long, help: "Install path")
  var installPrefix: String?

  @Option(name: .customLong("arch"), help: ArgumentHelp(valueName: "arch"))
  var archs: [TargetArch] = [.native]

  @Argument(help: ArgumentHelp(valueName: "argument"))
  var extraArguments: [String] = []

  func validate() throws {
    try preconditionOrThrow(!archs.isEmpty, "No arch!")
  }

  struct Description: Decodable {
    let name, path: String
    let targets: [Target]
    struct Target: Decodable {
      let c99name, module_type, name, path: String
      let sources: [String]
      let type: String
    }
  }

  func run() throws {

    try spmSetup(force: false)

    let launcher = TSCExecutableLauncher(outputRedirection: verbose ? .none : .stream(stdout: { _ in

    }, stderr: { _ in

    }))

    let installDirectoryURL = installPrefix.map {URL(fileURLWithPath: $0)}

    try installDirectoryURL.map { url in
      switch fm.fileExistance(at: url) {
      case .directory:
        break
      case .file:
        print("install prefix \(installPrefix!) is a file!")
        throw ExitCode(1)
      case .none:
        try fm.createDirectory(at: url)
      }
    }

    let spmBinaryDirectoryURL = URL(fileURLWithPath: ".build/\(spmProductDir)")
    try? fm.removeItem(at: spmBinaryDirectoryURL)
    try fm.createDirectory(at: spmBinaryDirectoryURL)

    if update {
      print("Updating...")
      try SwiftCommand.update
        .launch(use: launcher)
    }

    let result = try SwiftCommand.describe
      .launch(use: TSCExecutableLauncher())

    let p: Description = try JSONDecoder().kwiftDecode(from: result.output.get())

    let allArchs = Set(archs)
    for arch in allArchs {
      try build(arch: arch, launcher: launcher)
    }

    try p.targets.forEach { target in
      guard target.type == "executable" else {
        return
      }
      print("Creating universal binary for \(target.name)")

      let archBinaries = try allArchs.map { arch -> String in
        let triple = TargetTriple(arch: arch, system: .native)

        var src = URL(fileURLWithPath: ".build/\(triple.spmString)/\(mode)").appendingPathComponent(target.name)
        if strip {
          let strippedFileURL = src.appendingPathExtension("stripped")
          print("Stripping \(target.name)")
          if fm.fileExistance(at: strippedFileURL).exists {
            try fm.removeItem(at: strippedFileURL)
          }
          try fm.copyItem(at: src, to: strippedFileURL)
          try Strip(file: strippedFileURL.path)
            .launch(use: launcher)
          src = strippedFileURL
        }

        return src.path
      }

      let universalBinaryURL = spmBinaryDirectoryURL.appendingPathComponent(target.name)

      try Lipo(files: archBinaries, output: universalBinaryURL.path)
        .launch(use: launcher)

      try installDirectoryURL.map { url in
        let dst = url.appendingPathComponent(target.name)
        if fm.fileExistance(at: dst).exists {
          print("Removing installed file at \(dst.path)")
          try fm.removeItem(at: dst)
        }
        print("Installing \(target.name) to \(dst.path)")
        try fm.copyItem(at: universalBinaryURL, to: dst)
      }
    }
  }

  var mode: String {
    debug ? "debug" : "release"
  }



  func build(arch: TargetArch, launcher: TSCExecutableLauncher) throws {
    func removeGarbages() {
      try? fm.removeItem(at: URL(fileURLWithPath: ".build/\(mode).yaml"))
      try? fm.removeItem(at: URL(fileURLWithPath: ".build/\(mode)"))
    }

    print("Build arch \(arch) with \(mode) configuration")
    removeGarbages()
    let startDate = Date()
    try SwiftBuild(debug: debug, integrated: integrated, arch: arch, extraArguments: extraArguments)
      .launch(use: launcher)
    print("Totally used: \(Date().timeIntervalSince(startDate)) seconds")
    removeGarbages()
  }
}
