import URLFileManager
import Logging
import KwiftUtility

public struct BuildEnvironment {
  public let fm: URLFileManager = .init()
  public let version: PackageVersion
  public let source: PackageSource
  public let prefix: PackagePath

  /// requiered package dependencies, value is install prefix
  public let dependencyMap: PackageDependencyMap

  /// need to test or ...
  public let safeMode: Bool
  /// c compiler
  public let cc: String
  /// cpp compiler
  public let cxx: String

  /// the environment will be used to run processes
  public let environment: [String : String]

  public let parallelJobs: Int? = 8
  public let libraryType: PackageLibraryBuildType
  public let target: BuildTriple
  let logger: Logger

  public let sdkPath: String?
  public let deployTarget: String?

  var launcher: BuilderLauncher {
    .init(environment: environment)
  }

  public var host: BuildTriple { .native }

  public var isBuildingNative: Bool {
    target == host
  }

  public var isBuildingCross: Bool {
    !isBuildingNative
  }
}


// MARK: FM Utilities
extension BuildEnvironment {

  public func changingDirectory(_ path: String, create: Bool = true, block: (URL) throws -> ()) throws {
    try changingDirectory(URL(fileURLWithPath: path), create: create, block: block)
  }

  public func changingDirectory(_ url: URL, create: Bool = true,
                                // logger
                                block: (URL) throws -> ()) throws {
    if create {
      try fm.createDirectory(at: url, withIntermediateDirectories: true)
    }
    let oldDir = fm.fileManager.currentDirectoryPath
    FileManager.default.changeCurrentDirectoryPath(url.path)
    print("Current in:", url.path)
    defer {
      FileManager.default.changeCurrentDirectoryPath(oldDir)
      print("Back to:", oldDir)
    }
    try block(url)
  }


  public func removeItem(at url: URL) throws {
    try retry(body: try fm.removeItem(at: url))
  }

  public func mkdir(_ path: String) throws {
    try mkdir(URL(fileURLWithPath: path))
  }

  public func mkdir(_ url: URL) throws {
    try fm.createDirectory(at: url)
  }


  private func launch<T>(_ executable: T) throws where T : Executable {
    _ = try launcher.launch(executable: executable, options: .init(checkNonZeroExitCode: true))
  }

  public func launch(_ executableName: String, _ arguments: String?...) throws {
    try launch(executableName, arguments)
  }
  public func launch(_ executableName: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableName: executableName, arguments: arguments.compactMap {$0}))
  }
  public func launch(path: String, _ arguments: String?...) throws {
    try launch(path: path, arguments)
  }

  public func launch(path: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableURL: URL(fileURLWithPath: path), arguments: arguments.compactMap {$0}))
  }
}

// MARK: Common tools
extension BuildEnvironment {
  public func make(toolType: MakeToolType = .make,
                   _ targets: String...) throws {
    try launch(MakeTool(toolType: toolType,
                        parallelJobs: parallelJobs,
                        targets: targets))
  }

  public func rake(_ targets: String...) throws {
    try launch(Rake(jobs: parallelJobs ?? 0, targets: targets))
  }

  public func cmake(toolType: MakeToolType, _ arguments: String?...) throws {
    try cmake(toolType: toolType, arguments)
  }

  public func cmake(toolType: MakeToolType, _ arguments: [String?]) throws {
    var cmakeArguments = [
      "-DCMAKE_INSTALL_PREFIX=\(prefix.root.path)",
      "-DCMAKE_BUILD_TYPE=Release"
    ]
    arguments.forEach { argument in
      argument.map { cmakeArguments.append($0) }
    }
    switch toolType {
    case .ninja:
      cmakeArguments.append("-G")
      cmakeArguments.append("Ninja")
    default:
      break
    }
    if isBuildingCross {
      cmakeArguments.append(cmakeDefineFlag(target.arch.rawValue, "CMAKE_OSX_ARCHITECTURES"))
    }
    try launch("cmake", cmakeArguments)
  }

  public func meson(_ arguments: String?...) throws {
    try meson(arguments)
  }
  public func meson(_ arguments: [String?]) throws {
    try launch("meson",
               ["--prefix=\(prefix.root.path)",
                "--buildtype=release",
                //                "--wrap-mode=nofallback
               ]
               + arguments.compactMap {$0})
  }

  public func configure(_ arguments: String?...) throws {
    try configure(arguments)
  }

  public func configure(_ arguments: [String?]) throws {
    var configureArguments = ["--prefix=\(prefix.root.path)"]
    arguments.forEach { $0.map { configureArguments.append($0) } }

    if isBuildingCross {
      configureArguments.append("--host=\(target.tripleString)")
    }
    
    try launch(path: "configure", configureArguments)
  }

  public func autoreconf() throws {
    try launch("autoreconf", "-if")
  }

  public func autogen() throws {
    try launch(path: "autogen.sh")
  }
}
