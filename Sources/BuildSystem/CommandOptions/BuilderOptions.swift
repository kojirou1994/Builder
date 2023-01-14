import Precondition

struct BuilderOptions: ParsableArguments {
  @Option(name: .shortAndLong, help: "Library type, available: \(PackageLibraryBuildType.allCases.map(\.rawValue).joined(separator: ", "))")
  var library: PackageLibraryBuildType = .static

  @Option(help: "Customize the package version, if supported.")
  var version: Version?

  @Flag(help: "Build from HEAD")
  var head: Bool = false

//  @Flag(help: "Clean all built packages")
//  var clean: Bool = false

  @Option(help: "Set binary prefix")
  var binPrefix: String?

  @Option(help: "Set binary suffix")
  var binSuffix: String?

  @Flag(help: "Ignore package's tag.")
  var ignoreTag: Bool = false

  @Option(help: "Dependency level limit, must > 0.")
  var dependencyLevel: UInt?

  @Flag(help: "Install all dependencies together with target package.")
  var joinDependency: Bool = false

  @Option(help: "Rebuild level, package or tree.")
  var rebuildLevel: RebuildLevel?

  @Option(help: "Specify build/cache directory")
  var workPath: String = "./BuildSystemWorks"

  @Option(help: "Specify package storage directory")
  var packagePath: String = "./Packages"

  @Flag(inversion: .prefixedEnableDisable, help: "Enable bitcode.")
  var bitcode: Bool = false

  @Flag(inversion: .prefixedEnableDisable, help: "Enable strict mode, always test.")
  var strictMode: Bool = false

  @Flag(help: "Use system package if available.")
  var preferSystemPackage: Bool = false

  @Option(name: [.long, .customShort("O", allowingJoined: true)], help: "Specify which optimization level to use")
  var optimize: String?

  @Option
  var deployMode: DeployMode = .native

  func validate() throws {
    try preconditionOrThrow(!(version != nil && head), ValidationError("Both --version and --head is used, it's not allowed."))
    try preconditionOrThrow((dependencyLevel ?? 1) > 0, ValidationError("dependencyLevel must > 0"))
    if bitcode {
      try preconditionOrThrow(library == .static, ValidationError("bitcode is enabled, but libraryType is set to \(library), bitcode is only enabled in static library!"))
    }
  }

  var packageVersion: PackageVersion? {
    if head {
      return .head
    }
    if let v = version {
      return .stable(v)
    }
    return nil
  }
}

extension Builder {
  init(options: BuilderOptions, target: TargetTriple, addLibInfoInPrefix: Bool) throws {
    // TODO: use argument parser to parse environment
    // see: https://github.com/apple/swift-argument-parser/issues/4
    let cc = ProcessInfo.processInfo.environment[EnvironmentKey.cc.string] ?? TargetSystem.native.cc
    let cxx = ProcessInfo.processInfo.environment[EnvironmentKey.cxx.string] ?? TargetSystem.native.cxx

    try self.init(
      workDirectoryURL: URL(fileURLWithPath: options.workPath),
      packagesDirectoryURL: URL(fileURLWithPath: options.packagePath),
      cc: cc, cxx: cxx,
      target: target,
      ignoreTag: options.ignoreTag, dependencyLevelLimit: options.dependencyLevel,
      rebuildLevel: options.rebuildLevel, joinDependency: options.joinDependency,
      addLibInfoInPrefix: addLibInfoInPrefix,
      optimize: options.optimize, deployMode: options.deployMode,
      strictMode: options.strictMode, preferSystemPackage: options.preferSystemPackage,
      enableBitcode: options.bitcode)
  }
}

enum DeployMode: String, ExpressibleByArgument {
  case generic
  case native
}
