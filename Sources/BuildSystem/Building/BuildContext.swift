import URLFileManager
import Logging
import KwiftUtility
import ExecutableDescription

public class BuildContext {

  internal init(order: PackageOrder, source: PackageSource, prefix: PackagePath, dependencyMap: PackageDependencyMap, strictMode: Bool, cc: String, cxx: String, environment: EnvironmentValues, libraryType: PackageLibraryBuildType?, logger: Logger, enableBitcode: Bool, sdkPath: String?, deployTarget: String?, external: ExternalPackageEnvironment) {
    self.order = order
    self.source = source
    self.prefix = prefix
    self.dependencyMap = dependencyMap
    self.strictMode = strictMode
    self.cc = cc
    self.cxx = cxx
    self.environment = environment
    self._libraryType = libraryType

    self.logger = logger
    self.enableBitcode = enableBitcode
    self.sdkPath = sdkPath
    self.deployTarget = deployTarget
    self.external = external
  }

  internal let fm: URLFileManager = .init()
  public let order: PackageOrder

  public let source: PackageSource
  /// the install prefix for current building package
  public let prefix: PackagePath

  /// requiered package dependencies, value is install prefix
  public let dependencyMap: PackageDependencyMap

  public let external: ExternalPackageEnvironment
  /// need to test or ...
  public let strictMode: Bool

  public var canRunTests: Bool {
    strictMode
      && order.target.arch.canLaunch(arch: .native)
      && !order.target.system.isSimulator
      && ( (order.target.system == .native) || (order.target.system == .macCatalyst && TargetSystem.native == .macOS) )
  }

  /// c compiler
  public let cc: String
  /// cpp compiler
  public let cxx: String

  /// the environment will be used to run processes
  public var environment: EnvironmentValues

  public let parallelJobs: Int? = ProcessInfo.processInfo.processorCount + 2

  private var _libraryType: PackageLibraryBuildType?
  public internal(set) var libraryType: PackageLibraryBuildType {
    get {
      guard let v = _libraryType else {
        fatalError("Your package says no library type is supported, why access this property now?")
      }
      return v
    }
    set {
      _libraryType = newValue
    }
  }
  public let prefersStaticBin: Bool = false
  let logger: Logger

  public let enableBitcode: Bool
  public let sdkPath: String?
  public let deployTarget: String?

  public var launcher: BuilderLauncher {
    .init(environment: environment, outputRedirection: .none)
  }

}

// MARK: Target
extension BuildContext {
  public var host: TargetTriple { .native }

  public var isBuildingNative: Bool {
    order.target == host
  }

  public var isBuildingCross: Bool {
    !isBuildingNative
  }
}

// MARK: FM Utilities
extension BuildContext {

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

  public func createSymbolicLink(at url: URL, withDestinationURL destURL: URL) throws {
    logger.info("symbolic link \(destURL.path) to \(url.path)")
    try fm.createSymbolicLink(at: url, withDestinationURL: destURL)
  }

  public func mkdir(_ url: URL) throws {
    try fm.createDirectory(at: url)
  }

  public func copyItem(at srcURL: URL,
                       to dstURL: URL) throws {
    try fm.copyItem(at: srcURL, to: dstURL)
  }

  public func copyItem(at srcURL: URL,
                       toDirectory dstDirURL: URL) throws {
    try fm.copyItem(at: srcURL, toDirectory: dstDirURL)
  }

  public func moveItem(at srcURL: URL,
                       to dstURL: URL) throws {
    try fm.moveItem(at: srcURL, to: dstURL)
  }

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
extension BuildContext {

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
//      "--debug-output",
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

  public func mesonCrossFile() -> String {
    """
    [binaries]
    c = '\(cc)'
    objc = '\(cc)'
    cpp = '\(cxx)'
    ar = 'ar'
    ld = 'ld'
    strip = 'strip'
    cmake = 'cmake'
    pkgconfig = 'pkg-config'

    [host_machine]
    system = '\(order.target.system.mesonSystemName)'
    cpu_family = '\(order.target.arch.mesonCPUFamily)'
    cpu = '\(order.target.arch.clangTripleString)'
    endian = 'little'
    """
  }

  public func meson(_ arguments: [String?]) throws {
    var mesonArguments = ["--prefix=\(prefix.root.path)",
                     "--buildtype=release",
                     //                "--wrap-mode=nofallback
    ]
    if isBuildingCross {
      let crossFile = randomFilename + ".txt"
      try mesonCrossFile().write(toFile: crossFile, atomically: true, encoding: .utf8)
      mesonArguments.append("--cross-file")
      mesonArguments.append(crossFile)
    }
    mesonArguments += arguments.compactMap {$0}
    try launch("meson", mesonArguments)
  }

  public func configure(directory: String =  ".", _ arguments: [String?]) throws {
    var configureArguments = [
      "--prefix=\(prefix.root.path)",
      "--build=\(TargetTriple.native.gnuTripleString)",
      "--host=\(order.target.gnuTripleString)",
    ]

    arguments.forEach { $0.map { configureArguments.append($0) } }

    try launch(path: "\(directory)/configure", configureArguments)
  }

  public func autoreconf() throws {
    try launch("autoreconf", "-ivf")
  }

  public func autogen() throws {
    try launch(path: "autogen.sh")
  }
}


// MARK: Variadic Support

extension BuildContext {
  public func launch(_ executableName: String, _ arguments: String?...) throws {
    try launch(executableName, arguments)
  }

  public func launch(path: String, _ arguments: String?...) throws {
    try launch(path: path, arguments)
  }

  public func meson(_ arguments: String?...) throws {
    try meson(arguments)
  }

  public func configure(directory: String =  ".", _ arguments: String?...) throws {
    try configure(directory: directory, arguments)
  }
}


// MARK: Fix Autotools
extension BuildContext {
  /// call this function before configure
  public func fixAutotoolsForDarwin() throws {
    if isBuildingCross {
      try replace(contentIn: "configure", matching: "cross_compiling=no", with: "cross_compiling=yes")
    }
    if order.target.system == .macCatalyst {
      try replace(contentIn: "configure", matching: """
      \\$CC -dynamiclib
      """, with: """
      \\$CC -dynamiclib -target \(order.target.clangTripleString)
      """)

      try replace(contentIn: "configure", matching: """
      \\$CC \\$allow_undefined_flag
      """, with: """
      \\$CC \\$allow_undefined_flag -target \(order.target.clangTripleString)
      """)
    }
  }
}

extension BuildContext {
  public func fixDylibsID() throws {
    if order.target.system.isApple, libraryType.buildShared {
      try fm.contentsOfDirectory(at: prefix.lib)
        .filter { $0.pathExtension == TargetSystem.macOS.sharedLibraryExtension }
        .filter { try (fm.attributesOfItem(atURL: $0)[.type] as! FileAttributeType) == .typeRegular }
        .forEach { dylibURL in
          let dylibPath = dylibURL.path
          try launch("install_name_tool", "-id", dylibPath, dylibPath)
        }
    }
  }
}