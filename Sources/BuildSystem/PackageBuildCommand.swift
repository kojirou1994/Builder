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
    let checker = PackageUpdateChecker()
    let newVersions = try checker.check(package: T.defaultPackage)

    checker.logger.info("All valid new versions: \(newVersions)")
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
  var installOptions: InstallOptions

  @OptionGroup
  var package: T

  @Flag(inversion: .prefixedEnableDisable, help: "Add library target/type info in prefix")
  var prefixLibInfo: Bool = true

  var target: BuildTriple {
    .init(arch: arch, system: system)
  }

  public mutating func run() throws {
    dump(builderOptions.packageVersion)
    if info {
      print(package)
    } else {
      let builder = try Builder(options: builderOptions, target: target,
                                addLibInfoInPrefix: prefixLibInfo, deployTarget: deployTarget)

      let buildResult = try builder.startBuild(package: package, version: builderOptions.packageVersion)
      builder.logger.info("Package is installed at: \(buildResult.prefix.root.path)")

      if let installContent = installOptions.installContent {
        let fm: URLFileManager = .init()

        let installDestPrefix = URL(fileURLWithPath: installOptions.installPrefix)

        func install(from prefix: PackagePath) throws {
          let action = installOptions.uninstall ? "Uninstalling" : "Installing"
          builder.logger.info("\(action) from \(prefix)")
          let installSources: [URL]
          switch installContent {
          case .bin:
            installSources = [prefix.bin]
          case .lib:
            installSources = [prefix.include, prefix.lib]
          case .all:
            installSources = [prefix.root]
          case .pkgconfig:
            installSources = [prefix.pkgConfig]
          }

          installSources.forEach { installSource in
            guard let enumerator = fm.enumerator(at: installSource, options: [.skipsHiddenFiles]) else {
              // show error
              return
            }
            for case let url as URL in enumerator {
              if fm.fileExistance(at: url) == .file {
                let relativePath = url.path.dropFirst(prefix.root.path.count)
                  .drop(while: {"/" == $0 })

                let destURL = installDestPrefix.appendingPathComponent(String(relativePath))

                if installOptions.uninstall {
                  do {
                    if fm.fileExistance(at: destURL).exists {
                      print("removing \(destURL.path)")
                      try fm.removeItem(at: destURL)
                    }
                  } catch {
                    print("uninstall failed: \(error.localizedDescription)")
                  }
                } else {
                  print("\(relativePath) --> \(destURL.path)")
                  try! fm.createDirectory(at: destURL.deletingLastPathComponent())
                  do {
                    if fm.isDeletableFile(at: destURL), installOptions.forceInstall {
                      print("removing existed \(destURL.path)")
                      try fm.removeItem(at: destURL)
                    }
                    switch installOptions.installMethod {
                    case .link:
                      try fm.createSymbolicLink(at: destURL, withDestinationURL: url)
                    case .copy:
                      try fm.copyItem(at: url, to: destURL)
                    }
                  } catch {
                    print("install failed: \(error.localizedDescription)")
                  }
                }
              }
            }
          } // installSources forEach end
        } // install func end

        try install(from: buildResult.prefix)
        switch installOptions.installLevel {
        case .package:
          break
        case .runTime:
          try buildResult.runTimeDependencyMap.packageDependencies.values.forEach { prefix in
            try install(from: prefix)
          }
        case .all:
          try buildResult.dependencyMap.packageDependencies.values.forEach { prefix in
            try install(from: prefix)
          }
        }
      }
    }
  }
}

import ArgumentParser

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

  @Flag(help: "Keep temp files when packing xcframeworks.")
  var keepTemp: Bool = false

  @Flag(name: [.short], inversion: .prefixedEnableDisable, help: "If enabled, program will create framework to pack xcframework.")
  var autoModulemap: Bool = true

  public mutating func run() throws {
    var builtPackages = [BuildTargetSystem : [(arch: BuildArch, result: PackageBuildResult)]]()
    var failedTargets = [BuildTriple]()
    let unsupportedTargets = [BuildTriple]()

    for target in BuildTriple.allValid {
      do {
        print("Building \(target)")
        let builder = try Builder(options: builderOptions, target: target, addLibInfoInPrefix: true, deployTarget: nil)

        let result = try builder.startBuild(package: package, version: builderOptions.packageVersion)

        builtPackages[target.system, default: []].append((target.arch, result))
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

    func packXCFramework(libraryName: String, headers: [String]?, isStatic: Bool) throws {
      print("Packing xcframework from \(libraryName)...")

      let ext = isStatic ? "a" : "dylib"
      let libraryFilename = libraryName + "." + ext
      let output = "\(libraryName)_\(isStatic ? "static" : "dynamic").xcframework"

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
          libraryFileURL = systemPackages[0].result.prefix.lib.appendingPathComponent(libraryFilename)
            .resolvingSymlinksInPath()
        } else {
          try retry(body: fm.createDirectory(at: tmpDirectory))
          let fatOutput = tmpDirectory.appendingPathComponent(libraryFilename)
          let lipoArguments = ["-create", "-output", fatOutput.path]
            + systemPackages.map { $0.result.prefix.lib.appendingPathComponent(libraryFilename).path }
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
            try fm.copyItem(at: systemPackages[0].result.prefix.include.appendingPathComponent(headerFilename),
                            to: headerDstURL)
          }
        } else {
          headerIncludeDir = systemPackages[0].result.prefix.include
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

          let shimFilename = "\(libraryName)_shim.h"
          let shimURL = frameworkHeadersDirectory.appendingPathComponent(shimFilename)
          let shimContent = headerFiles.map { "#include \"\($0)\"" }.joined(separator: "\n")
          try shimContent
            .write(to: shimURL, atomically: true, encoding: .utf8)

          let modulemap = """
          framework module \(libraryName) {
          \(headerFiles.map { "//  header \"\($0)\"" }.joined(separator: "\n"))
            umbrella header "\(shimFilename)"
            export *
            module * { export * }
            //requires objc
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

    func packXCFramework(libraryName: String, headers: [String]?) throws {
      try packXCFramework(libraryName: libraryName, headers: headers, isStatic: builderOptions.library.buildStatic)
      if builderOptions.library == .all {
        try packXCFramework(libraryName: libraryName, headers: headers, isStatic: false)
      }
    }

    if let libraryName = packXc {
      try packXCFramework(libraryName: libraryName, headers: nil)
    }

    if autoPackXC {
      let products = builtPackages.values.first!.first!.result.products

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
  var library: PackageLibraryBuildType = .static

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
  var workPath: String = "./BuildSystemWorks"

  @Option(help: "Specify package storage directory")
  var packagePath: String = "./Packages"

  @Flag(inversion: .prefixedEnableDisable, help: "Enable bitcode.")
  var bitcode: Bool = false

  @Flag(inversion: .prefixedEnableDisable, help: "Enable strict mode, always test.")
  var strictMode: Bool = false

  @Flag(help: "Use system package if available.")
  var preferSystemPackage: Bool = false

  @Option(name: [.long, .customShort("O", allowingJoined: true)])
  var optimize: String?

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

extension Builder {
  init(options: BuilderOptions, target: BuildTriple, addLibInfoInPrefix: Bool, deployTarget: String?) throws {
    // TODO: use argument parser to parse environment
    // see: https://github.com/apple/swift-argument-parser/issues/4
    let cc = ProcessInfo.processInfo.environment[EnvironmentKey.cc.string] ?? BuildTargetSystem.native.cc
    let cxx = ProcessInfo.processInfo.environment[EnvironmentKey.cxx.string] ?? BuildTargetSystem.native.cxx

    try self.init(
      workDirectoryURL: URL(fileURLWithPath: options.workPath),
      packagesDirectoryURL: URL(fileURLWithPath: options.packagePath),
      cc: cc, cxx: cxx,
      libraryType: options.library, target: target,
      ignoreTag: options.ignoreTag, dependencyLevelLimit: options.dependencyLevel,
      rebuildLevel: options.rebuildLevel, joinDependency: options.joinDependency,
      cleanAll: options.clean, addLibInfoInPrefix: addLibInfoInPrefix, optimize: options.optimize, strictMode: options.strictMode, preferSystemPackage: options.preferSystemPackage,
      enableBitcode: options.bitcode, deployTarget: deployTarget)
  }
}

import ArgumentParser

public enum InstallContent: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case all
  case bin
  case lib
  case pkgconfig

  public var description: String { rawValue }
}

public enum InstallMethod: String, ExpressibleByArgument, CaseIterable, CustomStringConvertible {
  case link
  case copy

  public var description: String { rawValue }
}

struct InstallOptions: ParsableArguments {
  @Option(help: "Install content type, available: \(InstallContent.allCases.map(\.rawValue).joined(separator: ", "))")
  var installContent: InstallContent?

  @Option(help: "Install method, available: \(InstallMethod.allCases.map(\.rawValue).joined(separator: ", "))")
  var installMethod: InstallMethod = .link

  @Option(help: "Install level, available: \(RebuildLevel.allCases.map(\.rawValue).joined(separator: ", "))")
  var installLevel: RebuildLevel = .package

  @Option(help: "Install prefix")
  var installPrefix: String = "/usr/local"

  @Flag(help: "Install existed files")
  var forceInstall: Bool = false

  @Flag
  var uninstall: Bool = false
}
