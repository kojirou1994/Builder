import URLFileManager
import KwiftUtility
import Logging
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#else
#error("Unsupported platform!")
#endif
import ExecutableLauncher
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let buildSummaryFilename = ".build_summary"

extension ContiguousPipeline: CustomStringConvertible {
  public var description: String {
    processes.map { ([$0.executableURL!.path] + ($0.arguments ?? [])).joined(separator: " ") }.joined(separator: " | ")
  }
}

public enum RebuildLevel: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case package
  case runTime
  case all

  public var description: String { rawValue }
}

struct Builder {
  init(workDirectoryURL: URL,
       packagesDirectoryURL: URL,
       cc: String, cxx: String,
       libraryType: PackageLibraryBuildType,
       target: TargetTriple,
       ignoreTag: Bool, dependencyLevelLimit: UInt?,
       rebuildLevel: RebuildLevel?, joinDependency: Bool, cleanAll: Bool,
       addLibInfoInPrefix: Bool, optimize: String?,
       strictMode: Bool, preferSystemPackage: Bool,
       enableBitcode: Bool, deployTarget: String?) throws {
    self.builderDirectoryURL = workDirectoryURL
    self.workingDirectoryURL = workDirectoryURL.appendingPathComponent("working")
    self.downloadCacheDirectory = workDirectoryURL.appendingPathComponent("download")
    self.logger = Logger(label: "Builder")
    self.productsDirectoryURL = packagesDirectoryURL
    self.cleanAll = cleanAll
    self.ignoreTag = ignoreTag
    self.joinDependency = joinDependency
    self.dependencyLevelLimit = dependencyLevelLimit ?? UInt.max
    if joinDependency {
      self.rebuildLevel = nil
    } else {
      self.rebuildLevel = rebuildLevel
    }
    self.addLibInfoInPrefix = addLibInfoInPrefix
    self.optimize = optimize
    self.preferSystemPackage = preferSystemPackage

    let sdkPath: String?
    if target.system.needSdkPath {
      logger.info("Looking for sdk path for \(target.system)")
      sdkPath = try target.system.getSdkPath()
    } else {
      sdkPath = nil
    }

    var envValues = EnvironmentValues()
    envValues[.path] = ""
    if case let cargoHome = envValues["CARGO_HOME"],
       !cargoHome.isEmpty {
      logger.info("use cargo root from env: \(cargoHome)")
      envValues.append(cargoHome, for: .path)
    } else {
      let defaultCargoHome = fm.homeDirectoryForCurrentUser.appendingPathComponent(".cargo").appendingPathComponent("bin")
      if fm.fileExistance(at: defaultCargoHome) == .directory {
        let path = defaultCargoHome.path
        logger.info("use default cargo root: \(path)")
        envValues.append(path, for: .path)
      } else {
        logger.warning("Can't find cargo root, you may install rustup first.")
      }
    }

    do {
      let pyenvRoot = try AnyExecutable(executableName: "pyenv", arguments: ["root"])
        .launch(use: TSCExecutableLauncher(outputRedirection: .collect))
        .utf8Output()
        .trimmingCharacters(in: .whitespacesAndNewlines)
      logger.info("use pyenv root: \(pyenvRoot)")
      envValues.append("\(pyenvRoot)/shims", for: .path)
    } catch {
      logger.warning("Can't find pyenv root, you may install pyenv first.")
    }

    envValues.append("/usr/bin", for: .path)
    envValues.append("/bin", for: .path)
    envValues.append("/usr/sbin", for: .path)
    envValues.append("/sbin", for: .path)

    logger.info("Using PATH: \(envValues[.path])")
    
    self.env = .init(
      version: .head, source: .repository(url: "", requirement: .branch("main")),
      prefix: .init(productsDirectoryURL),
      dependencyMap: .init(),
      strictMode: strictMode,
      cc: cc, cxx: cxx,
      environment: envValues,
      libraryType: libraryType, target: target, logger: logger, enableBitcode: enableBitcode, sdkPath: sdkPath, deployTarget: deployTarget)

  }

  let session = URLSession(configuration: .ephemeral)
  let fm = URLFileManager.default
  let env: BuildEnvironment
  let logger: Logger
  let builderDirectoryURL: URL
  let workingDirectoryURL: URL
  let downloadCacheDirectory: URL
  let productsDirectoryURL: URL

  let rebuildLevel: RebuildLevel?
  let dependencyLevelLimit: UInt

  let ignoreTag: Bool
  let joinDependency: Bool
  let cleanAll: Bool
  let prefixGenerator: PrefixGenerator? = nil
  let addLibInfoInPrefix: Bool
  let optimize: String?
  let preferSystemPackage: Bool

  func checkout(package: Package, version: PackageVersion, source: PackageSource, directoryName: String) throws -> URL {
    let safeDirName = directoryName.safeFilename()
    let srcDirURL: URL

    switch source.requirement {
    case .repository(let requirement):
      switch requirement {
      case .branch(let branch), .tag(let branch):
        try env.launch("git", "clone", "-b", branch, "--depth", "1", "--recursive", source.url, safeDirName)
      case .none:
        fatalError()
      case .revision(_):
        fatalError("Useless api")
      }
      srcDirURL = URL(fileURLWithPath: safeDirName)
    case .tarball(sha256: _):
      let url = try URL(string: source.url).unwrap("Invalid url string: \(source.url)")
      let lastPathComponent = url.lastPathComponent
      var tarballExtension: String?
      for ext in [".tar.gz", ".tar.bz2", ".tar.xz"] {
        if lastPathComponent.hasSuffix(ext) {
          tarballExtension = ext
          break
        }
      }
      if tarballExtension == nil, case let ext = url.pathExtension, !ext.isEmpty {
        tarballExtension = "." + ext
      }
      let versionString: String
      switch version {
      case .head:
        versionString = UUID().uuidString
      case .stable(let v):
        versionString = v.toString()
      }
      let filename = "\(package.name)-\(versionString)\(tarballExtension ?? "")"
      let dstFileURL = downloadCacheDirectory.appendingPathComponent(filename)
      if !URLFileManager.default.fileExistance(at: dstFileURL).exists {
        logger.info("Downloading \(url.absoluteString) to memory...")
        let response = try session.syncResultTask(with: url).get()
        try preconditionOrThrow(200..<300 ~= (response.response as! HTTPURLResponse).statusCode,
                                "No ok response code!")
        logger.info("Writing data to file \(dstFileURL.path)")
        try response.data.write(to: dstFileURL)
      }

      #warning("handle other tarball format")
      try env.launch("tar", "xf", dstFileURL.path)

      let contents = try env.fm.contentsOfDirectory(at: env.fm.currentDirectory, options: [.skipsHiddenFiles])
      if contents.count == 1, env.fm.fileExistance(at: contents[0]) == .directory {
        srcDirURL = contents[0]
      } else {
        srcDirURL = env.fm.currentDirectory
      }
    }

    // Apply patches
    try source.patches.forEach { patch in
      logger.info("Applying patch \(patch)")
      switch patch {
      case .raw(_): break
      case let .remote(url: url, sha256: sha256):
        let patcher = try ContiguousPipeline(AnyExecutable(executableName: "curl", arguments: [url]))
          .append(AnyExecutable(executableName: "patch", arguments: ["-ruN", "-d", srcDirURL.path, "--verbose"]))
        print(patcher)
        try patcher.run()
        patcher.waitUntilExit()
      }
    }

    return srcDirURL
  }
}

typealias PrefixGenerator = (_ prefixRoot: URL, Package, PackageOrder, PackageRecipe, _ isJoinedDependency: Bool) -> URL

extension Builder {

  private func formPrefix(package: Package, order: PackageOrder, recipe: PackageRecipe,
                          isJoinedDependency: Bool = false) -> PackagePath {
    let result: URL
    if let generator = prefixGenerator {
      result = generator(env.prefix.root, package, order, recipe, isJoinedDependency)
    } else {
      var prefix = env.prefix.root

      // example root/curl/7.14-feature_hash/static-x86_64-macOS/
      prefix.appendPathComponent(package.name.safeFilename())

      var versionTag = order.version.description
      var tag = package.tag
      if !ignoreTag, !tag.isEmpty {
        let tagHash = tag.withUTF8 { buffer in
          SHA256.hash(data: buffer)
            .hexString(uppercase: false, prefix: "")
        }
        versionTag.append("-")
        versionTag.append(tagHash)
      }
      if isJoinedDependency {
        versionTag.append("-")
        versionTag.append("dependency")
      }
      prefix.appendPathComponent(versionTag.safeFilename())

      if addLibInfoInPrefix {
        var libInfos = [String]()
        if recipe.supportedLibraryType != nil {
          libInfos.append(env.libraryType.rawValue)
        }
        libInfos.append(order.target.arch.rawValue)
        libInfos.append(order.target.system.rawValue)
        prefix.appendPathComponent(libInfos.joined(separator: "-"))
      }

      result = prefix
    }

    return .init(result)
  }

  private func canStartBuild(packageSupported: PackageLibraryBuildType) -> Bool {
    switch (env.libraryType, packageSupported) {
    case (.shared, .shared),
         (.static, .static),
         (_, .all):
      return true
    default:
      return true
    }
  }


  private struct InternalBuildResult {
    let prefix: PackagePath
    let products: [PackageProduct]
    // add summary info
  }

  ///
  /// - Parameters:
  ///   - package: the package to be built
  ///   - version: override the default version
  ///   - prefix: override the default prefix
  ///   - dependencyMap: all dependencies for the package
  /// - Throws:
  /// - Returns: package installed prefix
  private func build(package: Package, order: PackageOrder,
             reason: BuildReason,
             prefix: PackagePath? = nil,
             dependencyMap: PackageDependencyMap) throws -> InternalBuildResult {

    let startTime = Date()

    let recipe = try package.recipe(for: order)
    try recipe.supportedLibraryType
      .map { try preconditionOrThrow(canStartBuild(packageSupported: $0)) }

    let usedPrefix: PackagePath
    var result: InternalBuildResult {
      .init(prefix: usedPrefix, products: recipe.products)
    }

    func summaryAndFinish() throws -> InternalBuildResult {
      let endTime = Date()

      let summary = PackageBuildSummary(order: order, startTime: startTime, endTime: endTime, reason: reason)
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
      logger.info("Writing summary...")
      try encoder.encode(summary).write(to: usedPrefix.appending(buildSummaryFilename))

      return result
    }

    if let v = prefix {
      usedPrefix = v
    } else {
      usedPrefix = formPrefix(package: package, order: order, recipe: recipe)
      if env.fm.fileExistance(at: usedPrefix.root.appendingPathComponent(buildSummaryFilename)).exists {
        logger.info("Built package existed.")
        // MARK: Rebuild Handling
        switch (rebuildLevel, reason) {
        case (.all, _),
             (.runTime, .dependency(package: _, time: .runTime)),
             (.runTime, .user),
             (.package, .user):
          logger.info("Rebuilding required, removing built package.")
          try env.removeItem(at: usedPrefix.root)
        default:
          return result
        }
      }
    }

    // MARK: Install system package, skip building
    if preferSystemPackage,
       case .dependency = reason,
       package.tag.isEmpty,
       case let sdkPath = self.env.sdkPath ?? "",
       let systemPackage = package.systemPackage(for: order, sdkPath: sdkPath) {
      logger.info("Using system package: \(package.name)")
      // auto generated pkgconfig

      let pkgConfigDirectoryURL = usedPrefix.pkgConfig
      try env.fm.createDirectory(at: pkgConfigDirectoryURL)
      try systemPackage.pkgConfigs.forEach { pkgConfig in
        logger.info("Writing system pkg config \(pkgConfig.name)")
        try pkgConfig.content
          .write(to: pkgConfigDirectoryURL
                  .appendingPathComponent(pkgConfig.name)
                  .appendingPathExtension("pc"),
                 atomically: true, encoding: .utf8)
      }

      return try summaryAndFinish()
    }

    // MARK: Setup Build Environment
    var environment = env.environment
    do {
      let allPrefixes = Set(dependencyMap.allPrefixes)

      // PKG_CONFIG_PATH
      environment[.pkgConfigPath] = allPrefixes
        .lazy.map(\.pkgConfig)
        .filter { fm.fileExistance(at: $0) == .directory }
        .map(\.path)
        .joined(separator: ":")

      /*
       ACLOCAL
       Doc: https://www.gnu.org/software/automake/manual/html_node/Macro-Search-Path.html
       */
      environment[.aclocalPath] = allPrefixes
        .lazy
        .map { $0.appending("share", "aclocal") }
        .filter { fm.fileExistance(at: $0) == .directory }
        .map(\.path)
        .joined(separator: ":")

      // PATH
      environment[.path] = (
        allPrefixes
          .lazy.map(\.bin)
          .filter { fm.fileExistance(at: $0) == .directory }
          .map(\.path)
          +
          environment[.path]
          .split(separator: ":")
          .map(String.init)
      ).joined(separator: ":")

      // TODO: keep user's flags?
      environment[.cflags] = ""
      environment[.cxxflags] = ""
      environment[.ldflags] = ""

      if order.target != .native { // isBuildingCross
        switch order.target.system {
        case .macCatalyst:
          /*
           Thanks:
           https://stackoverflow.com/questions/59903554/uikit-uikit-h-not-found-for-clang-building-mac-catalyst
           */
          environment.append("-target", for: .cflags, .cxxflags)
          environment.append(order.target.clangTripleString, for: .cflags, .cxxflags)
        default:
          environment.append("-arch", for: .cflags, .cxxflags)
          environment.append(order.target.arch.clangTripleString, for: .cflags, .cxxflags)
        }
        environment.append("-arch", for: .ldflags)
        environment.append(order.target.arch.clangTripleString, for: .ldflags)

        if let sysroot = env.sdkPath {
          environment.append("-isysroot", for: .cflags, .cxxflags)
          environment.append(sysroot, for: .cflags, .cxxflags)
        }
      }
      if env.enableBitcode {
        if recipe.supportsBitcode {
          let bitcodeFlag = "-fembed-bitcode"
          environment.append(bitcodeFlag, for: .cflags, .cxxflags)
          environment.append(bitcodeFlag, for: .ldflags)
        } else {
          logger.warning("Package doesn't support bitcode, but bitcode is enabled!")
        }
      }
      
      if let deployTarget = env.deployTarget {
        let flag = "\(env.order.target.system.minVersionClangFlag)=\(deployTarget)"
        environment.append(flag, for: .cflags, .cxxflags)
        environment.append(flag, for: .ldflags)
      }
      allPrefixes.forEach { prefix in
        if fm.fileExistance(at: prefix.include) == .directory {
          environment.append(prefix.cflag, for: .cflags, .cxxflags)
        }
        if fm.fileExistance(at: prefix.lib) == .directory {
          environment.append(prefix.ldflag, for: .ldflags)
        }
      }

      if let optimizeLevel = optimize {
        environment.append("-O\(optimizeLevel)", for: .cflags, .cxxflags)
      }

      environment[.cc] = env.cc
      environment[.cxx] = env.cxx
    }

    let env = newBuildEnvironment(
      version: order.version, source: recipe.source,
      target: order.target,
      dependencyMap: dependencyMap,
      environment: environment,
      prefix: usedPrefix)

    let tmpWorkDirURL = workingDirectoryURL.appendingPathComponent(package.name + UUID().uuidString)

    try env.fm.createDirectory(at: usedPrefix.root)
    do {
      // Start building
      try env.changingDirectory(tmpWorkDirURL) { _ in

        let srcDir = try checkout(package: package, version: order.version, source: recipe.source, directoryName: package.name)

        try env.changingDirectory(srcDir) { _ in
          try package.build(with: env)
        }
      }
    } catch {
      // build failed, remove if installed
      logger.error("Building failed, removing install prefix if has installed any files.")
      try? env.removeItem(at: usedPrefix.root)
      throw error
    }

    return try summaryAndFinish()
  }
}

public struct PackageBuildResult {
  public let prefix: PackagePath
  public let products: [PackageProduct]
  public let dependencyMap: PackageDependencyMap
  public let runTimeDependencyMap: PackageDependencyMap
}

extension Builder {
  public func startBuild(package: Package, version: PackageVersion?) throws -> PackageBuildResult {
    if cleanAll {
      print("Cleaning products directory...")
      try? env.removeItem(at: productsDirectoryURL)
    }
    print("Cleaning working directory...")
    try? env.removeItem(at: workingDirectoryURL)

    try env.mkdir(downloadCacheDirectory)

    let dependencyPrefix: PackagePath?
    let order = PackageOrder(version: version ?? package.defaultVersion, target: env.order.target)
    let recipe = try package.recipe(for: order)

    if joinDependency {
      dependencyPrefix = formPrefix(package: package, order: order, recipe: recipe, isJoinedDependency: true)
      if env.fm.fileExistance(at: dependencyPrefix!.root).exists {
        print("Removing dependency directory")
        try env.removeItem(at: dependencyPrefix!.root)
      }
    } else {
      dependencyPrefix = nil
    }

    let summary = try buildPackageAndDependencies(package: package, order: order, reason: nil, prefix: dependencyPrefix, parentLevel: 0)

    let buildResult = try build(package: package, order: order, reason: .user, dependencyMap: summary.dependencyMap)
    print("The built package is in \(buildResult.prefix.root.path)")
    return .init(prefix: buildResult.prefix, products: buildResult.products,
                 dependencyMap: summary.dependencyMap, runTimeDependencyMap: summary.runTimeDependencyMap)
  }

  private struct InternalBuildSummary {
    let packageSelfResult: InternalBuildResult?
    let dependencyMap: PackageDependencyMap
    let runTimeDependencyMap: PackageDependencyMap
    let level: Int
  }

  // return deps map
  private func buildPackageAndDependencies(
    package: Package, order: PackageOrder,
    reason: BuildReason?,
    prefix: PackagePath?, parentLevel: Int) throws -> InternalBuildSummary {

    logger.info("Building \(package.name), order: \(order)")
    let currentLevel = parentLevel + 1
    let dependencies = try package.recipe(for: order).dependencies

    var dependencyMap: PackageDependencyMap = .init()
    var runTimeDependencyMap: PackageDependencyMap = .init()

    if !dependencies.isEmpty {
      print("Dependencies:")
      print(dependencies)
    }

    if currentLevel <= dependencyLevelLimit {
      try dependencies.packages.forEach { dependencyPackage in
        let dependencySummary = try buildPackageAndDependencies(
          package: dependencyPackage.package,
          // TODO: Optional specific dependency's version
          order: .init(version: dependencyPackage.package.defaultVersion, target: dependencyPackage.options.target ?? order.target),
          reason: .dependency(package: package.name, time: dependencyPackage.requiredTime),
          prefix: prefix, parentLevel: currentLevel)
        switch dependencyPackage.requiredTime {
        case .buildTime: break
        case .runTime:
          runTimeDependencyMap.add(package: dependencyPackage.package, prefix: dependencySummary.packageSelfResult!.prefix)
          runTimeDependencyMap.merge(dependencySummary.runTimeDependencyMap)
        }
        dependencyMap.add(package: dependencyPackage.package, prefix: dependencySummary.packageSelfResult!.prefix)
        dependencyMap.merge(dependencySummary.runTimeDependencyMap)
      }
      try dependencies.otherPackages.forEach { otherPackages in
        switch otherPackages.manager {
        case .brew:
          dependencyMap.mergeBrewDependency(try parseBrewDeps(otherPackages.names, requireLinked: otherPackages.requireLinked))
          runTimeDependencyMap.mergeBrewDependency(try parseBrewDeps(otherPackages.names, requireLinked: otherPackages.requireLinked))
        default:
          logger.warning("Unimplemented other packages: \(otherPackages), continue in 4 seconds")
          sleep(4)
        }
      }

    } else {
      logger.info("Dependency level limit reached, dependencies are ignored.")
    }

    let result = try reason.map { try build(package: package, order: order, reason: $0, prefix: prefix, dependencyMap: dependencyMap) }

    return .init(packageSelfResult: result, dependencyMap: dependencyMap, runTimeDependencyMap: runTimeDependencyMap, level: currentLevel)
  }

  func newBuildEnvironment(
    version: PackageVersion, source: PackageSource,
    target: TargetTriple,
    dependencyMap: PackageDependencyMap,
    environment: EnvironmentValues,
    prefix: PackagePath) -> BuildEnvironment {
    .init(
      version: version, source: source,
      prefix: prefix, dependencyMap: dependencyMap,
      strictMode: env.strictMode, cc: env.cc, cxx: env.cxx,
      environment: environment,
      libraryType: env.libraryType, target: target, logger: env.logger, enableBitcode: env.enableBitcode, sdkPath: env.sdkPath, deployTarget: env.deployTarget)
  }
}
