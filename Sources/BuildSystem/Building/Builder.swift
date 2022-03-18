import URLFileManager
import KwiftUtility
import Precondition
import PrettyBytes
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
import Foundation

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
       target: TargetTriple,
       ignoreTag: Bool, dependencyLevelLimit: UInt?,
       rebuildLevel: RebuildLevel?, joinDependency: Bool,
       addLibInfoInPrefix: Bool, optimize: String?,
       strictMode: Bool, preferSystemPackage: Bool,
       enableBitcode: Bool) throws {
    self.builderDirectoryURL = workDirectoryURL
    self.workingDirectoryURL = workDirectoryURL.appendingPathComponent("working")
    self.downloadCacheDirectory = workDirectoryURL.appendingPathComponent("download")
    self.logger = Logger(label: "Builder")
    self.productsDirectoryURL = packagesDirectoryURL
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

    var external = ExternalPackageEnvironment()
    var envValues = EnvironmentValues()
    envValues[.path] = ""
    envValues[.pkgConfigPath] = ""

    // MARK: cargo
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

    envValues.append("/usr/bin", for: .path)
    envValues.append("/bin", for: .path)
    envValues.append("/usr/sbin", for: .path)
    envValues.append("/sbin", for: .path)

    logger.info("Using PATH: \(envValues[.path])")

    self.mainTarget = target
    self.packageRootPath = .init(productsDirectoryURL)
    self.cc = cc
    self.cxx = cxx
    self.strictMode = strictMode
    self.envValues = envValues
    self.enableBitcode = enableBitcode
    self.sdkPath = sdkPath

    self.external = external
    self.env = .init(
      order: .init(version: .head, target: target, libraryType: .all), source: .repository(url: "", requirement: .branch("main")),
      prefix: .init(productsDirectoryURL),
      dependencyMap: .init(),
      strictMode: strictMode,
      cc: cc, cxx: cxx,
      environment: envValues,
      libraryType: .all, logger: logger, enableBitcode: enableBitcode, sdkPath: sdkPath, external: external)

  }

  let session = URLSession(configuration: .ephemeral)
  let fm = URLFileManager.default
  /// base environment
  @available(*, deprecated, message: "move default values to builder root")
  let env: BuildContext
  let packageRootPath: PackagePath
  let mainTarget: TargetTriple
  let strictMode: Bool
  let cc: String, cxx: String
  let envValues: EnvironmentValues
  let enableBitcode: Bool
  let sdkPath: String?

  let external: ExternalPackageEnvironment

  let logger: Logger
  let builderDirectoryURL: URL
  let workingDirectoryURL: URL
  let downloadCacheDirectory: URL
  let productsDirectoryURL: URL

  let rebuildLevel: RebuildLevel?
  let dependencyLevelLimit: UInt

  let ignoreTag: Bool
  let joinDependency: Bool
  let prefixGenerator: PrefixGenerator? = nil
  let addLibInfoInPrefix: Bool
  let optimize: String?
  let preferSystemPackage: Bool

  func checkout(package: Package, version: PackageVersion, source: PackageSource, directoryName: String) throws -> URL {
    let safeDirName = directoryName.safeFilename()
    let srcDirURL: URL

    switch source.requirement {
    case .empty: return fm.currentDirectory
    case .repository(let requirement):
      switch requirement {
      case .branch(let branch), .tag(let branch):
        try env.launch("git", "clone", "-b", branch,
         "--depth", "1", "--recursive", "--shallow-submodules",
         source.url, safeDirName)
      case .none:
        try env.launch("git", "clone",
         "--depth", "1", "--recursive", "--shallow-submodules",
         source.url, safeDirName)
      case .revision(let revision):
        try env.launch("git", "clone", source.url, safeDirName)
        try env.changingDirectory(safeDirName) { _ in
          try env.launch("git", "checkout", revision)
          try env.launch("git", "submodule", "update", "--init", "--recursive", "--depth", "1", "--recommend-shallow")
        }
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

      let contents = try fm.contentsOfDirectory(at: env.fm.currentDirectory, options: [.skipsHiddenFiles])
      if contents.count == 1, fm.fileExistance(at: contents[0]) == .directory {
        srcDirURL = contents[0]
      } else {
        srcDirURL = fm.currentDirectory
      }
    }

    // Apply patches
    try source.patches.forEach { patch in
      logger.info("Applying patch \(patch)")
      var gitApply = AnyExecutable(executableName: "git", arguments: ["apply"])
      gitApply.currentDirectoryURL = srcDirURL
      switch patch {
      case .raw(let rawPatch):
        let pipe = Pipe()
        let patcher = try ContiguousPipeline(gitApply, standardInput: .pipe(pipe))
        try patcher.run()
        try pipe.fileHandleForWriting.kwiftWrite(contentsOf: Array(rawPatch.utf8))
        try pipe.fileHandleForWriting.close()
        patcher.waitUntilExit()
      case let .remote(url: url, sha256: _):
        let patcher = try ContiguousPipeline(AnyExecutable(executableName: "curl", arguments: [url]))
          .append(gitApply, isLast: true)

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
                          libraryType: PackageLibraryBuildType?,
                          isJoinedDependency: Bool = false) -> PackagePath {
    let result: URL
    if let generator = prefixGenerator {
      result = generator(packageRootPath.root, package, order, recipe, isJoinedDependency)
    } else {
      var prefix = packageRootPath.root

      // example root/curl/7.14-feature_hash/static-x86_64-macOS/
      prefix.appendPathComponent(package.name.safeFilename())

      var versionTag = order.version.description
      var tag = package.tag
      if !ignoreTag, !tag.isEmpty {
        let tagHash = tag.withUTF8 { buffer in
          BytesStringFormatter(uppercase: false)
            .bytesToHexString(SHA256.hash(data: buffer))
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
        libraryType.map { libType in
          libInfos.append(libType.rawValue)
        }
        libInfos.append(order.arch.rawValue)
        libInfos.append(order.system.rawValue)
        prefix.appendPathComponent(libInfos.joined(separator: "-"))
      }

      result = prefix
    }

    return .init(result)
  }

  private func shouldBuildLibraryTypeFor(order: PackageOrder, packageSupported: PackageLibraryBuildType?) -> PackageLibraryBuildType? {
    switch (order.libraryType, packageSupported) {
    case (.shared, .shared),
         (.static, .static),
         (_, .all):
      return order.libraryType
    case (.shared, .static), (.all, .static),
         (.static, .shared), (.all, .shared):
      return packageSupported
    case (_, nil):
      return nil
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
    let usedLibraryType = shouldBuildLibraryTypeFor(order: order, packageSupported: recipe.supportedLibraryType)
    logger.info("Ordered library type: \(order.libraryType), package supported: \(recipe.supportedLibraryType?.description ?? "none"), finally used: \(usedLibraryType?.description ?? "none")")

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
      usedPrefix = formPrefix(package: package, order: order, recipe: recipe, libraryType: usedLibraryType)
      if fm.fileExistance(at: usedPrefix.root.appendingPathComponent(buildSummaryFilename)).exists {
        logger.info("Built package existed.")
        // MARK: Rebuild Handling
        switch (rebuildLevel, reason) {
        case (.all, _),
             (.runTime, .dependency(package: _, time: .runTime)),
             (.runTime, .user),
             (.package, .user):
          logger.info("Rebuilding required, removing built package.")
          try fm.removeItem(at: usedPrefix.root)
        default:
          return result
        }
      }
    }

    // MARK: Install system package, skip building
    if preferSystemPackage,
       case .dependency = reason,
       package.tag.isEmpty,
       case let sdkPath = sdkPath ?? "",
       let systemPackage = package.systemPackage(for: order, sdkPath: sdkPath) {
      logger.info("Using system package: \(package.name)")
      // auto generated pkgconfig

      let pkgConfigDirectoryURL = usedPrefix.pkgConfig
      try fm.createDirectory(at: pkgConfigDirectoryURL)
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
    var environment = self.envValues
    do {
      let allPrefixes = Set(dependencyMap.allPrefixes)

      allPrefixes.forEach { prefix in
        // PKG_CONFIG_PATH
        let pkgconfig = prefix.pkgConfig
        if fm.fileExistance(at: pkgconfig) == .directory {
          environment.append(pkgconfig.path, for: .pkgConfigPath)
        }

        /*
         ACLOCAL
         Doc: https://www.gnu.org/software/automake/manual/html_node/Macro-Search-Path.html
         */

        let aclocal = prefix.appending("share", "aclocal")
        if fm.fileExistance(at: aclocal) == .directory {
          environment.append(aclocal.path, for: .aclocalPath)
        }
      }

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
      environment[.cmakePrefixPath] = environment[.path]

      // TODO: keep user's flags?
      environment[.cflags] = ""
      environment[.cxxflags] = ""
      environment[.ldflags] = ""

      if order.target != .native { // isBuildingCross
        if order.system == .macCatalyst {
          /*
           Thanks:
           https://stackoverflow.com/questions/59903554/uikit-uikit-h-not-found-for-clang-building-mac-catalyst
           */
          environment.append("-target", for: .cflags, .cxxflags, .ldflags)
          environment.append(order.target.clangTripleString, for: .cflags, .cxxflags, .ldflags)
        }
        environment.append("-arch", for: .cflags, .cxxflags, .ldflags)
        environment.append(order.arch.clangTripleString, for: .cflags, .cxxflags, .ldflags)

        if let sysroot = sdkPath {
          environment.append("-isysroot", for: .cflags, .cxxflags)
          environment.append(sysroot, for: .cflags, .cxxflags)
          if order.system == .macCatalyst {
            environment.append("-iframework", for: .ldflags)
            environment.append(sysroot + "/System/iOSSupport/System/Library/Frameworks", for: .ldflags)
            environment.append("-L\(sysroot)/System/iOSSupport/usr/lib", for: .ldflags)
          }
        }
      }
      if enableBitcode {
        if recipe.supportsBitcode {
          environment.append("-fembed-bitcode", for: .cflags, .cxxflags, .ldflags)
        } else {
          logger.warning("Package doesn't support bitcode, but bitcode is enabled!")
        }
      }
      
//      if let deployTarget = deployTarget {
//        let flag = "\(order.system.minVersionClangFlag)=\(deployTarget)"
//        environment.append(flag, for: .cflags, .cxxflags)
//        environment.append(flag, for: .ldflags)
//      }
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

      environment[.cc] = cc
      environment[.cxx] = cxx
    }

    let env = newBuildEnvironment(
      order: order, source: recipe.source,
      dependencyMap: dependencyMap,
      environment: environment, libraryType: usedLibraryType,
      prefix: usedPrefix)

    let tmpWorkDirURL = workingDirectoryURL.appendingPathComponent(genRandomFilename(prefix: package.name + "-", length: 8))

    try env.fm.createDirectory(at: usedPrefix.root)
    do {
      // Start building
      try env.changingDirectory(tmpWorkDirURL) { _ in

        let srcDir = try checkout(package: package, version: order.version, source: recipe.source, directoryName: package.name)

        try env.changingDirectory(srcDir) { _ in
          // TODO: re-checkout or make clean ?
          if usedLibraryType == .all, !recipe.canBuildAllLibraryTogether {
            // build separately
            func build(libraryType: PackageLibraryBuildType) throws {
              let savedEnv = env.environment
              defer {
                env.environment = savedEnv
              }
              env.libraryType = libraryType
              try package.build(with: env)
            }

            if env.prefersStaticBin {
              try build(libraryType: .shared)
              try build(libraryType: .static)
            } else {
              try build(libraryType: .static)
              try build(libraryType: .shared)
            }
          } else {
            try package.build(with: env)
          }
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
  public func startBuild(package: Package, version: PackageVersion?, libraryType: PackageLibraryBuildType) throws -> PackageBuildResult {
    print("Cleaning working directory...")
    try? retry(body: fm.removeItem(at: workingDirectoryURL))

    try fm.createDirectory(at: downloadCacheDirectory)

    let dependencyPrefix: PackagePath?
    let order = PackageOrder(version: version ?? package.defaultVersion, target: mainTarget, libraryType: libraryType)
    let recipe = try package.recipe(for: order)

    if joinDependency {
      dependencyPrefix = formPrefix(package: package, order: order, recipe: recipe, libraryType: order.libraryType, isJoinedDependency: true)
      if fm.fileExistance(at: dependencyPrefix!.root).exists {
        print("Removing dependency directory")
        try fm.removeItem(at: dependencyPrefix!.root)
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
      /// include runtime deps tree
    var runTimeDependencyMap: PackageDependencyMap = .init()

    if !dependencies.isEmpty {
      print("Dependencies:")
      print(dependencies)
    }

    if currentLevel <= dependencyLevelLimit {
      try dependencies.lazy.map(\.dependency).forEach { dependency in

        switch dependency {
        case .package(let dependencyPackage, options: let options):
          let dependencySummary = try buildPackageAndDependencies(
            package: dependencyPackage,
            // TODO: Optional specific dependency's version
            order: .init(version: dependencyPackage.defaultVersion, target: options.target ?? order.target, libraryType: options.libraryType ?? order.libraryType),
            reason: .dependency(package: package.name, time: options.requiredTime),
            prefix: prefix, parentLevel: currentLevel)

          switch options.requiredTime {
          case .buildTime: break
          case .runTime:
            runTimeDependencyMap.add(package: dependencyPackage, prefix: dependencySummary.packageSelfResult!.prefix)
            if !options.excludeDependencyTree {
              runTimeDependencyMap.merge(dependencySummary.runTimeDependencyMap)
            }
          }
          dependencyMap.add(package: dependencyPackage, prefix: dependencySummary.packageSelfResult!.prefix)
          // don't include buildTime deps tree
          if !options.excludeDependencyTree {
            dependencyMap.merge(dependencySummary.runTimeDependencyMap)
          }
        case let .other(manager: manager, names: names, requireLinked: requireLinked):
          if names.isEmpty {
            return
          }
          switch manager {
          case .brew:
            dependencyMap.mergeBrewDependency(try parseBrewDeps(names, requireLinked: requireLinked))
            runTimeDependencyMap.mergeBrewDependency(try parseBrewDeps(names, requireLinked: requireLinked))
          default:
            logger.warning("Unimplemented other package manager \(manager)'s, required packages: \(names), continue in 4 seconds")
            sleep(4)
          }
        }

      }

    } else {
      logger.info("Dependency level limit reached, dependencies are ignored.")
    }

    let result = try reason.map { try build(package: package, order: order, reason: $0, prefix: prefix, dependencyMap: dependencyMap) }

    return .init(packageSelfResult: result, dependencyMap: dependencyMap, runTimeDependencyMap: runTimeDependencyMap, level: currentLevel)
  }

  func newBuildEnvironment(
    order: PackageOrder, source: PackageSource,
    dependencyMap: PackageDependencyMap,
    environment: EnvironmentValues,
    libraryType: PackageLibraryBuildType?,
    prefix: PackagePath) -> BuildContext {
    .init(
      order: order, source: source,
      prefix: prefix, dependencyMap: dependencyMap,
      strictMode: strictMode, cc: cc, cxx: cxx,
      environment: environment,
      libraryType: libraryType, logger: env.logger, enableBitcode: enableBitcode, sdkPath: sdkPath, external: external)
  }
}
