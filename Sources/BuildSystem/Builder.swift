import URLFileManager
import KwiftUtility
import Logging
import CryptoKit

struct Builder {
  init(builderDirectoryURL: URL,
       cc: String, cxx: String,
       libraryType: PackageLibraryBuildType,
       target: BuildTriple,
       rebuildDependnecy: Bool, cleanAll: Bool,
       deployTarget: String?) throws {
    self.builderDirectoryURL = builderDirectoryURL
    self.srcRootDirectoryURL = builderDirectoryURL.appendingPathComponent("working")
    self.downloadCacheDirectory = builderDirectoryURL.appendingPathComponent("download")
    self.logger = Logger(label: "Builder")
    self.productsDirectoryURL = builderDirectoryURL.appendingPathComponent("products")
    self.cleanAll = cleanAll
    self.rebuildDependnecy = rebuildDependnecy

    let sdkPath: String?
    if target.system.needSdkPath {
      logger.info("Looking for sdk path for \(target.system)")
      sdkPath = try target.system.getSdkPath()
    } else {
      sdkPath = nil
    }
    
    self.env = .init(
      version: .head, source: .branch(repo: ""),
      prefix: .init(root: productsDirectoryURL),
      dependencyMap: .init(),
      safeMode: false,
      cc: cc, cxx: cxx,
      environment: ProcessInfo.processInfo.environment,
      libraryType: libraryType, target: target, logger: logger, sdkPath: sdkPath, deployTarget: deployTarget)

  }


  let env: BuildEnvironment
  let logger: Logger
  let builderDirectoryURL: URL
  let srcRootDirectoryURL: URL
  let downloadCacheDirectory: URL
  let productsDirectoryURL: URL

  let rebuildDependnecy: Bool

  let cleanAll: Bool

  func checkout(source: PackageSource, directoryName: String) throws -> URL {
    let safeDirName = directoryName.safeFilename()
    switch source.requirement {
    case .revisionItem(let revision):
      try env.launch("git", "clone", source.url, safeDirName)
      return URL(fileURLWithPath: safeDirName)
    case .tarball(filename: let filename):
      let url = URL(string: source.url)!
      let filename = filename ?? url.lastPathComponent
      let dstFileURL = downloadCacheDirectory.appendingPathComponent(filename)
      if !URLFileManager.default.fileExistance(at: dstFileURL).exists {
        let tmpFileURL = dstFileURL.appendingPathExtension("tmp")
        if env.fm.fileExistance(at: tmpFileURL).exists {
          try env.removeItem(at: tmpFileURL)
        }
        try env.launch("wget", "-O", tmpFileURL.path, url.absoluteString)
        try URLFileManager.default.moveItem(at: tmpFileURL, to: dstFileURL)
      }

      try env.launch("tar", "xf", dstFileURL.path)

      let uncompressedURL = URL(fileURLWithPath: dstFileURL.deletingPathExtension().deletingPathExtension().lastPathComponent)
//      try URLFileManager.default.moveItem(at: uncompressedURL, to: URL(fileURLWithPath: directory))
      return uncompressedURL
    default: fatalError()
    }
  }
}

extension Builder {

  func formPrefix(package: Package, version: PackageVersion) -> PackagePath {
    var prefix = env.prefix.root

    // example root/x86_64-macOS/static/curl/7.14-feature_hash
    prefix.appendPathComponent("\(env.target.arch.rawValue)-\(env.target.system.rawValue)")
    prefix.appendPathComponent(env.libraryType.description)
    prefix.appendPathComponent(package.name.safeFilename())
    var versionTag = version.description
    var tag = package.tag
    if !tag.isEmpty {
      let tagHash = tag.withUTF8 { buffer in
        SHA256.hash(data: buffer).hexString(uppercase: false, prefix: "")
      }
      versionTag.append("-")
      versionTag.append(tagHash)
    }
    prefix.appendPathComponent(versionTag.safeFilename())
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
  func build(package: Package, version: String? = nil,
             prefix: PackagePath? = nil,
             dependencyMap: PackageDependencyMap) throws -> PackagePath {

    var usedSource = package.source
    var usedVersion = package.version

    if let v = version {
      if let s = package.packageSource(for: .stable(v)) {
        print("Using custom version: \(v), source: \(s)")
        usedSource = s
        usedVersion = .stable(v)
      } else {
        print("Invalid custom version: \(v), use default source!")
      }
    }

    let usedPrefix: PackagePath
    if let v = prefix {
      usedPrefix = v
    } else {
      usedPrefix = formPrefix(package: package, version: usedVersion)
      if env.fm.fileExistance(at: usedPrefix.root).exists { // Already built
        if rebuildDependnecy {
          try env.removeItem(at: usedPrefix.root)
        } else {
          return usedPrefix
        }
      }
    }

    // MARK: Setup Build Environment
    var environment = env.environment
    do {
      let allPrefixes = dependencyMap.allPrefixes

      // PKG_CONFIG_PATH
      environment["PKG_CONFIG_PATH"] = allPrefixes.map(\.pkgConfig.path).joined(separator: ":")

      // PATH
      var paths = allPrefixes.map(\.bin.path)
      paths.append(contentsOf: environment["PATH", default: ""].split(separator: ":").map(String.init))

      environment["PATH"] = paths.joined(separator: ":")

      // ARCH
      var cflags = environment["CFLAGS", default: ""].split(separator: " ").map(String.init)
      var ldlags = environment["LDLAGS", default: ""].split(separator: " ").map(String.init)
      if env.isBuildingCross {
        cflags.append("-arch")
        cflags.append(env.target.arch.rawValue)
        if let sysroot = env.sdkPath {
          cflags.append("-isysroot")
          cflags.append(sysroot)
        }

        /*
         todo:
         -miphoneos-version-min=7.0
         -fembed-bitcode
         */

      }
      if let deployTarget = env.deployTarget {
        cflags.append("\(env.target.system.minVersionClangFlag)=\(deployTarget)")
      }
      allPrefixes.forEach { prefix in
        cflags.append("-I\(prefix.include.path)")
        ldlags.append("-L\(prefix.lib.path)")
      }
      
      environment["CFLAGS"] = cflags.joined(separator: " ")
      environment["CXXFLAGS"] = cflags.joined(separator: " ")
      environment["LDLAGS"] = ldlags.joined(separator: " ")

      environment["CC"] = env.cc
      environment["CXX"] = env.cxx
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

        let srcDir = try checkout(source: usedSource, directoryName: package.name)

        try env.changingDirectory(srcDir) { _ in
          try package.build(with: env)
        }
      }
    } catch {
      // build failed, remove if installed
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
  func startBuild(package: Package, version: String?) throws {
    if cleanAll {
      print("Cleaning products directory...")
      try? env.removeItem(at: productsDirectoryURL)
    }
    print("Cleaning working directory...")
    try? env.removeItem(at: srcRootDirectoryURL)

    try env.mkdir(downloadCacheDirectory)

    let summary = try buildDeps(package: package, buildSelf: false)

    let prefix = try build(package: package, version: version, dependencyMap: summary.dependencyMap)
    print("The built package is in \(prefix.root.path)")
  }

  struct BuildSummary {
    let prefix: PackagePath?
    let dependencyMap: PackageDependencyMap
  }

  // return deps map
  private func buildDeps(package: Package,
                                  buildSelf: Bool) throws -> BuildSummary {
    let dependencies = package.dependencies

    print("Building \(package.name)")

    var dependencyMap: PackageDependencyMap = .init()

    if !dependencies.isEmpty {
      print("Dependencies:")
      print(package.dependencies)
    }

    try dependencies.packages.forEach { depPackage in
      let summary = try buildDeps(package: depPackage, buildSelf: true)
      dependencyMap.add(package: depPackage, prefix: summary.prefix!)
      dependencyMap.merge(summary.dependencyMap)
    }

    dependencyMap.mergeBrewDependency(try parseBrewDeps(dependencies.brewFormulas))

    let prefix = try buildSelf ? build(package: package, dependencyMap: dependencyMap) : nil

    return .init(prefix: prefix, dependencyMap: dependencyMap)
  }

  func newBuildEnvironment(
    version: PackageVersion, source: PackageSource,
    dependencyMap: PackageDependencyMap,
    environment: [String : String],
    prefix: PackagePath) -> BuildEnvironment {
    .init(
      version: version, source: source,
      prefix: prefix, dependencyMap: dependencyMap,
      safeMode: env.safeMode, cc: env.cc, cxx: env.cxx,
      environment: environment,
      libraryType: env.libraryType, target: env.target, logger: env.logger, sdkPath: env.sdkPath, deployTarget: env.deployTarget)
  }
}
