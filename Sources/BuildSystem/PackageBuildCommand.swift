//import TSCBasic
//import TSCUtility
import ExecutableLauncher
import URLFileManager
import KwiftUtility
import XcodeExecutable
import Logging
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Version {
  var testGroup: [Version] {
    [nextPatch, nextMinor, nextMajor]
  }
}

public struct PackageCheckUpdateCommand<T: Package>: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(commandName: T.name,
          abstract: "",
          discussion: "")
  }

  public init() {}

  public func run() throws {
    let logger = Logger(label: "check-update")
    logger.info("Checking update info for package \(T.name)")
    let defaultPackage = T.defaultPackage
    let stableVersion = try defaultPackage.defaultVersion.stableVersion.unwrap("No stable version")
    logger.info("Current version: \(stableVersion)")
    let session = URLSession(configuration: .ephemeral)

    var failedVersions = Set<Version>()
    var updateVersions = Set<Version>()
    
    func test(versions: [Version]) -> [Version] {
      Set(versions).compactMap { version in
        if !failedVersions.contains(version),
           !updateVersions.contains(version),
           let source = defaultPackage.packageSource(for: .stable(version)) {
          logger.info("Testing version \(version)")
          switch source.requirement {
          case .repository:
            break
          case .tarball(sha256: _):
            do {
              var request = URLRequest(url: URL(string: source.url)!)
              request.httpMethod = "HEAD"
              let response = try session.syncResultTask(with: request).get()
              let statusCode = (response.response as! HTTPURLResponse).statusCode
              try preconditionOrThrow(200..<300 ~= statusCode, "status code: \(statusCode)")
              logger.info("New version: \(version)")
              updateVersions.insert(version)
              return version
            } catch {
              logger.error("\(error)")
            }
          }
        }
        failedVersions.insert(version)
        return nil
      }
    }

    var testVersions = stableVersion.testGroup
    while case let newVersions = test(versions: testVersions),
          !newVersions.isEmpty {
      testVersions = newVersions.flatMap(\.testGroup)
    }

    logger.info("All valid new versions: \(updateVersions.sorted())")
  }
}

public struct PackageBuildCommand<T: Package>: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(commandName: T.name,
          abstract: "",
          discussion: "")
  }

  public init() {}

  @Flag()
  var info: Bool = false

  @Option()
  var arch: BuildArch = .native

  @Option()
  var system: BuildTargetSystem = .native

  @Option(help: "Set target system version.")
  var deployTarget: String?

  @OptionGroup
  var builderOptions: BuilderOptions

  @OptionGroup
  var package: T

  public mutating func run() throws {
    dump(builderOptions.packageVersion)
    if info {
      print(package)
    } else {
      #if canImport(Darwin)
      let cc = ProcessInfo.processInfo.environment["CC"] ?? "clang"
      let cxx = ProcessInfo.processInfo.environment["CXX"] ?? "clang++"
      #else
      let cc = ProcessInfo.processInfo.environment["CC"] ?? "gcc"
      let cxx = ProcessInfo.processInfo.environment["CXX"] ?? "g++"
      #endif
      let builder = try Builder(
        builderDirectoryURL: URL(fileURLWithPath: builderOptions.buildPath),
        cc: cc, cxx: cxx,
        libraryType: builderOptions.library, target: .init(arch: arch, system: system),
        ignoreTag: builderOptions.ignoreTag, dependencyLevelLimit: builderOptions.dependencyLevel,
        rebuildLevel: builderOptions.rebuildLevel, joinDependency: builderOptions.joinDependency, cleanAll: builderOptions.clean, enableBitcode: builderOptions.enableBitcode, deployTarget: deployTarget)

      let installedPrefix = try builder.startBuild(package: package, version: builderOptions.packageVersion)
      builder.logger.info("Package is installed at: \(installedPrefix.root.path)")
    }
  }
}

public struct PackageBuildAllCommand<T: Package>: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(commandName: T.name,
          abstract: "",
          discussion: "")
  }

  public init() {}

  @OptionGroup
  var builderOptions: BuilderOptions

  @OptionGroup
  var package: T

  @Option(help: "Pack xcframework using specific library(.a) filename.")
  var packXc: String?

  @Flag(help: "Auto pack xcframework, if package supports.")
  var autoPackXC: Bool = false

  @Flag(inversion: .prefixedEnableDisable, help: "If enabled, program will create framework to pack xcframework.")
  var autoModulemap: Bool = true

  public mutating func run() throws {
    var builtPackages = [BuildTargetSystem : [(arch: BuildArch, prefix: PackagePath)]]()
    var failedTargets = [BuildTriple]()
    var unsupportedTargets = [BuildTriple]()

    for target in BuildTriple.allValid {
      guard package.supports(target: target) else {
        unsupportedTargets.append(target)
        continue
      }
      do {
        print("Building \(target)")
        let builder = try Builder(
          builderDirectoryURL: URL(fileURLWithPath: builderOptions.buildPath),
          cc: "clang", cxx: "clang++",
          libraryType: builderOptions.library, target: target,
          ignoreTag: builderOptions.ignoreTag, dependencyLevelLimit: builderOptions.dependencyLevel,
          rebuildLevel: builderOptions.rebuildLevel, joinDependency: builderOptions.joinDependency, cleanAll: builderOptions.clean, enableBitcode: builderOptions.enableBitcode, deployTarget: nil)

        let prefix = try builder.startBuild(package: package, version: builderOptions.packageVersion)

        builtPackages[target.system, default: []].append((target.arch, prefix))
      } catch {
        print("ERROR!", error)
        failedTargets.append(target)
      }
    }
    print("\n\n\n")
    print("FAILED TARGETS:", failedTargets)
    print("UNSUPPORTED TARGETS:", unsupportedTargets)

    if builtPackages.isEmpty {
      print("NO BUILT PACKAGES!")
      return
    }

    let fm = URLFileManager.default

    func packXCFramework(libraryName: String, headers: [String]?) throws {
      print("Packing xcframework from \(libraryName)...")

      #warning("maybe other library format")
      let libraryFilename = libraryName + ".a"
      let output = "\(libraryName).xcframework"

      if case let outputURL = URL(fileURLWithPath: output),
         fm.fileExistance(at: outputURL).exists {
        print("Remove old xcframework.")
        try retry(body: fm.removeItem(at: outputURL))
      }
      let xcTempDirectory = URL(fileURLWithPath: "PACK_XC-\(UUID().uuidString)")
      try retry(body: fm.createDirectory(at: xcTempDirectory))
      defer {
//        try? retry(body: fm.removeItem(at: lipoWorkingDirectory))
      }

      var createXCFramework = XcodeCreateXCFramework(output: output)

      try builtPackages.forEach { (system, systemPackages) in

        precondition(!systemPackages.isEmpty)
        let libraryFileURL: URL
        let tmpDirectory = xcTempDirectory.appendingPathComponent("\(system)-\(systemPackages.map(\.arch.rawValue).joined(separator: "_"))")
        if systemPackages.count == 1 {
          libraryFileURL = systemPackages[0].prefix.lib.appendingPathComponent(libraryFilename)
            .resolvingSymlinksInPath()
        } else {
          try retry(body: fm.createDirectory(at: tmpDirectory))
          let fatOutput = tmpDirectory.appendingPathComponent(libraryFilename)
          let lipoArguments = ["-create", "-output", fatOutput.path]
            + systemPackages.map { $0.prefix.lib.appendingPathComponent(libraryFilename).path }
          let lipo = AnyExecutable(executableName: "lipo",
                                   arguments: lipoArguments)
          try lipo.launch(use: TSCExecutableLauncher(outputRedirection: .none))
          libraryFileURL = fatOutput
        }

        let headerIncludeDir: URL
        if let specificHeaders = headers {
          headerIncludeDir = tmpDirectory.appendingPathComponent("include")
          try fm.createDirectory(at: headerIncludeDir)
          try specificHeaders.forEach { headerFilename in
            let headerDstURL = headerIncludeDir.appendingPathComponent(headerFilename)
            let headerSuperDirectory = headerDstURL.deletingLastPathComponent()
            try fm.createDirectory(at: headerSuperDirectory)
            try fm.copyItem(at: systemPackages[0].prefix.include.appendingPathComponent(headerFilename),
                            to: headerDstURL)
          }
        } else {
          headerIncludeDir = systemPackages[0].prefix.include
        }
        if autoModulemap {
          // create tmp framework
          let frameworkName = libraryName + ".framework"
          let tmpFrameworkDirectory = tmpDirectory.appendingPathComponent(frameworkName)
          try fm.createDirectory(at: tmpFrameworkDirectory)
          let frameworkHeadersDirectory = tmpFrameworkDirectory.appendingPathComponent("Headers")

          try fm.copyItem(at: headerIncludeDir, to: frameworkHeadersDirectory)

          let frameworkModulesDirectory = tmpFrameworkDirectory.appendingPathComponent("Modules")

          try fm.createDirectory(at: frameworkModulesDirectory)

          var headerFiles = [String]()
          _ = fm.forEachContent(in: frameworkHeadersDirectory) { file in
            if file.pathExtension == "h" {
              var relativePath = file.path.dropFirst(frameworkHeadersDirectory.path.count)
              if relativePath.hasPrefix("/") {
                relativePath.removeFirst()
              }
              headerFiles.append(String(relativePath))
            }
          }

          let modulemap = """
          framework module \(libraryName) {
          \(headerFiles.map { "  header \"\($0)\"" }.joined(separator: "\n"))
            export *
            // module * { export * }
          }
          """
          try modulemap.write(to: frameworkModulesDirectory.appendingPathComponent("module.modulemap"), atomically: true, encoding: .utf8)

          try fm.copyItem(at: libraryFileURL, to: tmpFrameworkDirectory.appendingPathComponent(libraryName))

          createXCFramework.components.append(.framework(tmpFrameworkDirectory.path))
        } else {
          createXCFramework.components.append(.library(libraryFileURL.path, header: headerIncludeDir.path))
        }
      }

      /*
       https://developer.apple.com/forums/thread/666335
       It seems like using lipo for these combinations might be necessary:
       ios-arm64-simulator and ios-x86_64-simulator
       ios-arm64-maccatalyst and ios-x86_64-maccatalyst
       macos-x86_64 and macos-arm64
       */

      print()
      print()
      try createXCFramework
        .launch(use: TSCExecutableLauncher(outputRedirection: .none))
    }

    if let libraryName = packXc {
      try packXCFramework(libraryName: libraryName, headers: nil)
    }

    if autoPackXC {
      let products = package.products

      try products.forEach { product in
        switch product {
        case let .library(name: libraryName, headers: headers):
          try packXCFramework(libraryName: libraryName, headers: headers)
        default:
          break
        }
      }
    }
  }
}

import Version
import ArgumentParser

extension Version: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(tolerant: argument)
  }
}

struct BuilderOptions: ParsableArguments {
  @Option(name: .shortAndLong, help: "Library type, available: \(PackageLibraryBuildType.allCases.map(\.rawValue).joined(separator: ", "))")
  var library: PackageLibraryBuildType = .statik

  @Option(help: "Customize the package version, if supported.")
  var version: Version?

  @Flag(help: "Build from HEAD")
  var head: Bool = false

  @Flag(help: "Clean all built packages")
  var clean: Bool = false

  @Flag(help: "Ignore package's tag.")
  var ignoreTag: Bool = false

  @Option(help: "Dependency level limit, must > 0.")
  var dependencyLevel: UInt?

  @Flag(help: "Install all dependencies together with target package.")
  var joinDependency: Bool = false

  @Option(help: "Rebuild level, package or tree.")
  var rebuildLevel: RebuildLevel?

  @Option(help: "Specify build/cache directory")
  var buildPath: String = "./builder"

  @Flag(help: "Enable bitcode.")
  var enableBitcode: Bool = false

  func validate() throws {
    try preconditionOrThrow(!(version != nil && head), ValidationError("Both --version and --head is used, it's not allowed."))
    try preconditionOrThrow((dependencyLevel ?? 1) > 0, ValidationError("dependencyLevel must > 0"))
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
