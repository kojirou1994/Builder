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
import Version
import ExecutableLauncher

extension ContiguousPipeline: CustomStringConvertible {
  public var description: String {
    processes.map { ([$0.executableURL!.path] + ($0.arguments ?? [])).joined(separator: " ") }.joined(separator: " | ")
  }
}

public enum RebuildLevel: String, ExpressibleByArgument {
  case package
  case tree
}

struct Builder {
  init(builderDirectoryURL: URL,
       cc: String, cxx: String,
       libraryType: PackageLibraryBuildType,
       target: BuildTriple,
       ignoreTag: Bool, dependencyLevelLimit: UInt?,
       rebuildLevel: RebuildLevel?, joinDependency: Bool, cleanAll: Bool,
       enableBitcode: Bool, deployTarget: String?) throws {
    self.builderDirectoryURL = builderDirectoryURL
    self.srcRootDirectoryURL = builderDirectoryURL.appendingPathComponent("working")
    self.downloadCacheDirectory = builderDirectoryURL.appendingPathComponent("download")
    self.logger = Logger(label: "Builder")
    self.productsDirectoryURL = builderDirectoryURL.appendingPathComponent("products")
    self.cleanAll = cleanAll
    self.ignoreTag = ignoreTag
    self.joinDependency = joinDependency
    self.dependencyLevelLimit = dependencyLevelLimit ?? UInt.max
    if joinDependency {
      self.rebuildLevel = nil
    } else {
      self.rebuildLevel = rebuildLevel
    }

    let sdkPath: String?
    if target.system.needSdkPath {
      logger.info("Looking for sdk path for \(target.system)")
      sdkPath = try target.system.getSdkPath()
    } else {
      sdkPath = nil
    }
    
    self.env = .init(
      version: .head, source: .repository(url: "", requirement: .branch("main")),
      prefix: .init(root: productsDirectoryURL),
      dependencyMap: .init(),
      safeMode: false,
      cc: cc, cxx: cxx,
      environment: .init(),
      libraryType: libraryType, target: target, logger: logger, enableBitcode: enableBitcode, sdkPath: sdkPath, deployTarget: deployTarget)

  }


  let env: BuildEnvironment
  let logger: Logger
  let builderDirectoryURL: URL
  let srcRootDirectoryURL: URL
  let downloadCacheDirectory: URL
  let productsDirectoryURL: URL

  let rebuildLevel: RebuildLevel?
  let dependencyLevelLimit: UInt

  let ignoreTag: Bool
  let joinDependency: Bool
  let cleanAll: Bool

  func checkout(package: Package, version: PackageVersion, source: PackageSource, directoryName: String) throws -> URL {
    let safeDirName = directoryName.safeFilename()
    let srcDirURL: URL

    switch source.requirement {
    case .repository(let requirement):
      switch requirement {
      case .branch(let branch), .tag(let branch):
        try env.launch("git", "clone", "-b", branch, "--depth", "1", "--recursive", source.url, safeDirName)
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
        let tmpFileURL = dstFileURL.appendingPathExtension("tmp")
        if env.fm.fileExistance(at: tmpFileURL).exists {
          try env.removeItem(at: tmpFileURL)
        }
        try env.launch("wget", "-O", tmpFileURL.path, url.absoluteString)
        try URLFileManager.default.moveItem(at: tmpFileURL, to: dstFileURL)
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
      let patcher = try ContiguousPipeline(AnyExecutable(executableName: "curl", arguments: [patch.url]))
        .append(AnyExecutable(executableName: "patch", arguments: ["-ruN", "-d", srcDirURL.path, "--verbose"]))
      print(patcher)
      try patcher.run()
      patcher.waitUntilExit()
    }

    return srcDirURL
  }
}

extension Builder {

  func formPrefix(package: Package, version: PackageVersion,
                  suffix: String = "") -> PackagePath {
    var prefix = env.prefix.root

    // example root/curl/7.14-feature_hash/static-x86_64-macOS/
    prefix.appendPathComponent(package.name.safeFilename())

    var versionTag = version.description
    var tag = package.tag
    if !ignoreTag, !tag.isEmpty {
      let tagHash = tag.withUTF8 { buffer in
        SHA256.hash(data: buffer)
          .hexString(uppercase: false, prefix: "")
      }
      versionTag.append("-")
      versionTag.append(tagHash)
    }
    if !suffix.isEmpty {
      versionTag.append("-")
      versionTag.append(suffix)
    }
    prefix.appendPathComponent(versionTag.safeFilename())

    prefix.appendPathComponent("\(env.libraryType)-\(env.target.arch.rawValue)-\(env.target.system.rawValue)")

    return .init(root: prefix)
  }

  ///
  /// - Parameters:
  ///   - package: the package to be built
  ///   - version: override the default version
  ///   - prefix: override the default prefix
  ///   - dependencyMap: all dependencies for the package
  /// - Throws:
  /// - Returns: package installed prefix
  func build(package: Package, version: PackageVersion? = nil,
             isDependency: Bool,
             prefix: PackagePath? = nil,
             dependencyMap: PackageDependencyMap) throws -> PackagePath {

    let usedVersion = version ?? package.defaultVersion

    guard let usedSource = package.packageSource(for: usedVersion) else {
      fatalError()
    }

    let usedPrefix: PackagePath
    if let v = prefix {
      usedPrefix = v
    } else {
      usedPrefix = formPrefix(package: package, version: usedVersion)
      if env.fm.fileExistance(at: usedPrefix.root).exists { // Already built
        logger.info("Built package existed.")
        switch (rebuildLevel, isDependency) {
        case (.tree, _), (.package, false):
          logger.info("Rebuilding required, removing built package.")
          try env.removeItem(at: usedPrefix.root)
        default:
          return usedPrefix
        }
      }
    }

    enum CommonEnvKey: String {
      case pkgConfigPath = "PKG_CONFIG_PATH"
      case path = "PATH"
      case cflags = "CFLAGS"
      case ldflags = "LDFLAGS"
    }

    // MARK: Setup Build Environment
    var environment = env.environment
    do {
      let allPrefixes = Set(dependencyMap.allPrefixes)

      // PKG_CONFIG_PATH
      environment[.pkgConfigPath] = allPrefixes.map(\.pkgConfig.path).joined(separator: ":")

      // PATH
      var paths = allPrefixes.map(\.bin.path)
      paths.append(contentsOf: environment[.path].split(separator: ":").map(String.init))

      environment[.path] = paths.joined(separator: ":")

      // ARCH
      var cflags = environment[.cflags].split(separator: " ").map(String.init)
      var ldlags = environment[.ldflags].split(separator: " ").map(String.init)
      if env.isBuildingCross {
        switch env.target.system {
        case .macCatalyst:
          /*
           Thanks:
           https://stackoverflow.com/questions/59903554/uikit-uikit-h-not-found-for-clang-building-mac-catalyst
           */
          cflags.append("-target")
          cflags.append(env.target.clangTripleString)
        default:
          cflags.append("-arch")
          cflags.append(env.target.arch.clangTripleString)
        }
        ldlags.append("-arch")
        ldlags.append(env.target.arch.clangTripleString)
        if let sysroot = env.sdkPath {
          cflags.append("-isysroot")
          cflags.append(sysroot)
        }
      }
      if env.enableBitcode {
        if package.supportsBitcode {
          cflags.append("-fembed-bitcode")
          ldlags.append("-fembed-bitcode")
        } else {
          print("Package doesn't support bitcode!")
        }
      }
      
      if let deployTarget = env.deployTarget {
        cflags.append("\(env.target.system.minVersionClangFlag)=\(deployTarget)")
        ldlags.append("\(env.target.system.minVersionClangFlag)=\(deployTarget)")
      }
      allPrefixes.forEach { prefix in
        cflags.append("-I\(prefix.include.path)")
        ldlags.append("-L\(prefix.lib.path)")
      }

      cflags.append("-O2")
      
      environment[.cflags] = cflags.joined(separator: " ")
      environment[.cxxflags] = cflags.joined(separator: " ")
      environment[.ldflags] = ldlags.joined(separator: " ")

      environment[.cc] = env.cc
      environment[.cxx] = env.cxx
    }

    let env = newBuildEnvironment(
      version: usedVersion, source: usedSource,
      dependencyMap: dependencyMap,
      environment: environment,
      prefix: usedPrefix)

    let tmpWorkDirURL = srcRootDirectoryURL.appendingPathComponent(package.name + UUID().uuidString)

    do {
      // Start building
      try env.changingDirectory(tmpWorkDirURL) { _ in

        let srcDir = try checkout(package: package, version: usedVersion, source: usedSource, directoryName: package.name)

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

    return usedPrefix
  }
}

public func replace(contentIn file: URL, matching string: String, with newString: String) throws {
  try String(contentsOf: file)
    .replacingOccurrences(of: string, with: newString)
    .write(to: file, atomically: true, encoding: .utf8)
}

public func replace(contentIn file: String, matching string: String, with newString: String) throws {
  try replace(contentIn: URL(fileURLWithPath: file), matching: string, with: newString)
}

extension Builder {
  func startBuild(package: Package, version: PackageVersion?) throws -> PackagePath {
    if cleanAll {
      print("Cleaning products directory...")
      try? env.removeItem(at: productsDirectoryURL)
    }
    print("Cleaning working directory...")
    try? env.removeItem(at: srcRootDirectoryURL)

    try env.mkdir(downloadCacheDirectory)

    let dependencyPrefix: PackagePath?
    let usedVersion: PackageVersion = version ?? package.defaultVersion
    if joinDependency {
      dependencyPrefix = formPrefix(package: package, version: usedVersion, suffix: "dependency")
      if env.fm.fileExistance(at: dependencyPrefix!.root).exists {
        print("Removing dependency directory")
        try env.removeItem(at: dependencyPrefix!.root)
      }
    } else {
      dependencyPrefix = nil
    }

    let summary = try buildPackageAndDependencies(package: package, version: usedVersion, buildSelf: false, prefix: dependencyPrefix, parentLevel: 0)

    let prefix = try build(package: package, version: version, isDependency: false, dependencyMap: summary.dependencyMap)
    print("The built package is in \(prefix.root.path)")
    return prefix
  }

  struct BuildSummary {
    let prefix: PackagePath?
    let dependencyMap: PackageDependencyMap
    let level: Int
  }

  // return deps map
  private func buildPackageAndDependencies(
    package: Package, version: PackageVersion,
    buildSelf: Bool, prefix: PackagePath?, parentLevel: Int) throws -> BuildSummary {

    logger.info("Building \(package.name)")
    let currentLevel = parentLevel + 1
    let dependencies = package.dependencies(for: version)

    var dependencyMap: PackageDependencyMap = .init()

    if !dependencies.isEmpty {
      print("Dependencies:")
      print(dependencies)
    }

    if currentLevel <= dependencyLevelLimit {
      try dependencies.packages.forEach { depPackage in
        let summary = try buildPackageAndDependencies(
          package: depPackage.package,
          // TODO: Optional specific dependency's version
          version: depPackage.package.defaultVersion,
          buildSelf: true, prefix: prefix, parentLevel: currentLevel)
        dependencyMap.add(package: depPackage.package, prefix: summary.prefix!)
        dependencyMap.merge(summary.dependencyMap)
      }
      dependencyMap.mergeBrewDependency(try parseBrewDeps(dependencies.brewFormulas))
    } else {
      logger.info("Dependency level limit reached, dependencies are ignored.")
    }

    let prefix = try buildSelf ? build(package: package, isDependency: true, prefix: prefix, dependencyMap: dependencyMap) : nil

    return .init(prefix: prefix, dependencyMap: dependencyMap, level: currentLevel)
  }

  func newBuildEnvironment(
    version: PackageVersion, source: PackageSource,
    dependencyMap: PackageDependencyMap,
    environment: EnvironmentValues,
    prefix: PackagePath) -> BuildEnvironment {
    .init(
      version: version, source: source,
      prefix: prefix, dependencyMap: dependencyMap,
      safeMode: env.safeMode, cc: env.cc, cxx: env.cxx,
      environment: environment,
      libraryType: env.libraryType, target: env.target, logger: env.logger, enableBitcode: env.enableBitcode, sdkPath: env.sdkPath, deployTarget: env.deployTarget)
  }
}
