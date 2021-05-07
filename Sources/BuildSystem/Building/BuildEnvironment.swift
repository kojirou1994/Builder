import URLFileManager
import Logging
import KwiftUtility
import ExecutableDescription

public class BuildEnvironment {

  internal init(version: PackageVersion, source: PackageSource, prefix: PackagePath, dependencyMap: PackageDependencyMap, strictMode: Bool, cc: String, cxx: String, environment: EnvironmentValues, libraryType: PackageLibraryBuildType, target: TargetTriple, logger: Logger, enableBitcode: Bool, sdkPath: String?, deployTarget: String?) {
    self.order = .init(version: version, target: target)
    self.source = source
    self.prefix = prefix
    self.dependencyMap = dependencyMap
    self.strictMode = strictMode
    self.cc = cc
    self.cxx = cxx
    self.environment = environment
    self.libraryType = libraryType

    self.logger = logger
    self.enableBitcode = enableBitcode
    self.sdkPath = sdkPath
    self.deployTarget = deployTarget
  }  

  
  internal let fm: URLFileManager = .init()
  public let order: PackageOrder
  @available(*, deprecated, renamed: "order.version")
  public var version: PackageVersion {
    order.version
  }
  @available(*, deprecated, renamed: "order.target")
  public var target: TargetTriple {
    order.target
  }
  public let source: PackageSource
  public let prefix: PackagePath

  /// requiered package dependencies, value is install prefix
  public let dependencyMap: PackageDependencyMap

  /// need to test or ...
  public let strictMode: Bool

  public var canRunTests: Bool {
    strictMode && order.target.arch == .native && !order.target.system.isSimulator
      && ( (order.target.system == .native) || (order.target.system == .macCatalyst && TargetSystem.native == .macOS) )
  }

  /// c compiler
  public let cc: String
  /// cpp compiler
  public let cxx: String

  /// the environment will be used to run processes
  public var environment: EnvironmentValues

  public let parallelJobs: Int? = ProcessInfo.processInfo.processorCount + 2
  public let libraryType: PackageLibraryBuildType
  public let prefersStaticBin: Bool = false
  let logger: Logger

  public let enableBitcode: Bool
  public let sdkPath: String?
  public let deployTarget: String?

  public var launcher: BuilderLauncher {
    .init(environment: environment)
  }

}

// MARK: Target
extension BuildEnvironment {
  public var host: TargetTriple { .native }

  public var isBuildingNative: Bool {
    order.target == host
  }

  public var isBuildingCross: Bool {
    !isBuildingNative
  }
}

// MARK: FM Utilities
extension BuildEnvironment {

  public func changingDirectory(_ path: String, _ block: (URL) throws -> ()) throws {
    try changingDirectory(URL(fileURLWithPath: path), block)
  }

  public func inRandomDirectory(_ block: (URL) throws -> ()) throws {
    try changingDirectory(randomFilename, block)
  }

  public func changingDirectory(_ url: URL, create: Bool = true,
                                // logger
                                _ block: (URL) throws -> ()) throws {
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

  public var randomFilename: String {
    genRandomFilename(prefix: "BuildEnvironment-", length: 6)
  }

  /// some package ignore the library setting, call this method to remove extra library files
  /// - Throws: remove file error
  public func autoRemoveUnneedLibraryFiles() throws {
    let searchExtension: String
    switch libraryType {
    case .all: return
    case .shared: searchExtension = "a"
    case .static: searchExtension = order.target.system.sharedLibraryExtension
    }
    let dstFiles = try fm.contentsOfDirectory(at: prefix.lib)
      .filter { $0.pathExtension.caseInsensitiveCompare(searchExtension) == .orderedSame }
    try dstFiles.forEach { try removeItem(at: $0) }
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

  public func copyItem(at srcURL: URL,
                       to dstURL: URL) throws {}

  public func copyItem(at srcURL: URL,
                       toDirectory dstDirURL: URL) throws {}

  public func moveItem(at srcURL: URL,
                       to dstURL: URL) throws {}

  private func launch<T>(_ executable: T) throws where T : Executable {
    _ = try launcher.launch(executable: executable, options: .init(checkNonZeroExitCode: true))
  }

  public func launch(_ executableName: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableName: executableName, arguments: arguments.compactMap {$0}))
  }

  public func launch(path: String, _ arguments: [String?]) throws {
    try launch(AnyExecutable(executableURL: URL(fileURLWithPath: path), arguments: arguments.compactMap {$0}))
  }

  public func launchResult(_ executableName: String, _ arguments: [String?]) throws -> LaunchResult {
    fatalError()
  }

  public func launchResult(path: String, _ arguments: [String?]) throws -> LaunchResult {
    fatalError()
  }
}

public typealias LaunchResult = BuilderLauncher.LaunchResult

// MARK: Common Build Systems
extension BuildEnvironment {

  public func make(toolType: MakeToolType = .make,
                   parallelJobs: Int? = nil,
                   _ targets: String...) throws {
    try launch(MakeTool(toolType: toolType,
                        parallelJobs: parallelJobs ?? self.parallelJobs,
                        targets: targets))
  }

  public func cmake(toolType: MakeToolType, _ arguments: String?...) throws {
    try cmake(toolType: toolType, arguments)
  }

  public func cmake(toolType: MakeToolType, _ arguments: [String?]) throws {
    var cmakeArguments = [
      cmakeDefineFlag(prefix.root.path, "CMAKE_INSTALL_PREFIX"),
      cmakeDefineFlag("Release", "CMAKE_BUILD_TYPE")
    ]
    switch toolType {
    case .ninja:
      cmakeArguments.append("-G")
      cmakeArguments.append("Ninja")
    default:
      break
    }
    if isBuildingCross {
      cmakeArguments.append(cmakeDefineFlag(order.target.arch.clangTripleString, "CMAKE_OSX_ARCHITECTURES"))
      cmakeArguments.append(cmakeDefineFlag(order.target.arch.gnuTripleString, "CMAKE_SYSTEM_PROCESSOR"))
      if order.target.system.isApple {
        cmakeArguments.append(cmakeDefineFlag("Darwin", "CMAKE_SYSTEM_NAME"))
      }
    }
    if let sysroot = sdkPath {
      cmakeArguments.append(cmakeDefineFlag(sysroot, "CMAKE_OSX_SYSROOT"))
    }
    cmakeArguments.append(cmakeDefineFlag(dependencyMap.allPrefixes.map(\.root.path).joined(separator: ";"), "CMAKE_PREFIX_PATH"))

    arguments.forEach { argument in
      argument.map { cmakeArguments.append($0) }
    }

    try launch("cmake", cmakeArguments)
  }

  public func meson(_ arguments: [String?]) throws {
    try launch("meson",
               ["--prefix=\(prefix.root.path)",
                "--buildtype=release",
                //                "--wrap-mode=nofallback
               ]
               + arguments.compactMap {$0})
  }



  public func configure(_ arguments: [String?]) throws {
    var configureArguments = ["--prefix=\(prefix.root.path)"]

    configureArguments.append("--host=\(order.target.gnuTripleString)")

    arguments.forEach { $0.map { configureArguments.append($0) } }

    try launch(path: "configure", configureArguments)
  }

  public func autoreconf() throws {
    try launch("autoreconf", "-ivf")
  }

  public func autogen() throws {
    try launch(path: "autogen.sh")
  }
}


// MARK: Variadic Support

extension BuildEnvironment {
  public func launch(_ executableName: String, _ arguments: String?...) throws {
    try launch(executableName, arguments)
  }

  public func launch(path: String, _ arguments: String?...) throws {
    try launch(path: path, arguments)
  }

  public func meson(_ arguments: String?...) throws {
    try meson(arguments)
  }

  public func configure(_ arguments: String?...) throws {
    try configure(arguments)
  }
}


// MARK: Fix Autotools
extension BuildEnvironment {
  public func fixAutotoolsForDarwin() throws {
    if order.target.system.isSimulator {
      try replace(contentIn: "configure", matching: "cross_compiling=no", with: "cross_compiling=yes")
    }
    if order.target.system == .macCatalyst {
      try replace(contentIn: "configure", matching: """
      archive_cmds="\\$CC -dynamiclib
      """, with: """
      archive_cmds="\\$CC -dynamiclib -target \(order.target.clangTripleString)
      """)
    }
  }
}
