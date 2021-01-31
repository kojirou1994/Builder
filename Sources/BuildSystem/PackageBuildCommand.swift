//import TSCBasic
//import TSCUtility
import ExecutableLauncher
import URLFileManager
import KwiftUtility

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
    if info {
      print(package)
    } else {
      let builder = try Builder(
        builderDirectoryURL: URL(fileURLWithPath: builderOptions.buildPath),
        cc: "clang", cxx: "clang++",
        libraryType: builderOptions.library, target: .init(arch: arch, system: system),
        rebuildDependnecy: builderOptions.rebuildDependnecy, joinDependency: builderOptions.joinDependency, cleanAll: builderOptions.clean, enableBitcode: builderOptions.enableBitcode, deployTarget: deployTarget)

      try builder.startBuild(package: package, version: builderOptions.version)
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
          rebuildDependnecy: builderOptions.rebuildDependnecy, joinDependency: builderOptions.joinDependency, cleanAll: builderOptions.clean, enableBitcode: builderOptions.enableBitcode, deployTarget: nil)

        let prefix = try builder.startBuild(package: package, version: builderOptions.version)

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
      let lipoWorkingDirectory = URL(fileURLWithPath: "PACK_XC-\(UUID().uuidString)")
      try retry(body: fm.createDirectory(at: lipoWorkingDirectory))
      defer {
        //        try? retry(body: fm.removeItem(at: lipoWorkingDirectory))
      }
      var args = ["-create-xcframework", "-output", output]
      try builtPackages.forEach { package in
        precondition(!package.value.isEmpty)
        let libraryFileURL: URL
        let tmpDirectory = lipoWorkingDirectory.appendingPathComponent("\(package.key)-\(package.value.map(\.arch.rawValue).joined(separator: "_"))")
        if package.value.count == 1 {
          libraryFileURL = package.value[0].prefix.lib.appendingPathComponent(libraryFilename)
            .resolvingSymlinksInPath()
        } else {
          try retry(body: fm.createDirectory(at: tmpDirectory))
          let fatOutput = tmpDirectory.appendingPathComponent(libraryFilename)
          let lipoArguments = ["-create", "-output", fatOutput.path]
            + package.value.map { $0.prefix.lib.appendingPathComponent(libraryFilename).path }
          let lipo = AnyExecutable(executableName: "lipo",
                                   arguments: lipoArguments)
          try lipo.launch(use: TSCExecutableLauncher(outputRedirection: .none))
          libraryFileURL = fatOutput
        }
        args.append("-library")
        args.append(libraryFileURL.path)
        args.append("-headers")
        let headerIncludeDir: URL
        if let specificHeaders = headers {
          headerIncludeDir = tmpDirectory.appendingPathComponent("include")
          try fm.createDirectory(at: headerIncludeDir)
          try specificHeaders.forEach { headerFilename in
            let headerDstURL = headerIncludeDir.appendingPathComponent(headerFilename)
            let headerSuperDirectory = headerDstURL.deletingLastPathComponent()
            try fm.createDirectory(at: headerSuperDirectory)
            try fm.copyItem(at: package.value[0].prefix.include.appendingPathComponent(headerFilename),
                            to: headerDstURL)
          }
        } else {
          headerIncludeDir = package.value[0].prefix.include
        }
        args.append(headerIncludeDir.path)
      }

      /*
       https://developer.apple.com/forums/thread/666335
       It seems like using lipo for these combinations might be necessary:
       ios-arm64-simulator and ios-x86_64-simulator
       ios-arm64-maccatalyst and ios-x86_64-maccatalyst
       macos-x86_64 and macos-arm64
       */

      print()
      print(args.joined(separator: " "))
      print()
      try AnyExecutable(executableName: "xcodebuild",
                        arguments: args)
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

struct BuilderOptions: ParsableArguments {
  @Option(name: .shortAndLong, help: "Library type, available: \(PackageLibraryBuildType.allCases.map(\.rawValue).joined(separator: ", "))")
  var library: PackageLibraryBuildType = .statik

  @Option(help: "Customize the package version, if supported.")
  var version: String?

  @Flag(help: "Clean all built packages")
  var clean: Bool = false

  @Flag(help: "Install all dependencies together with target package.")
  var joinDependency: Bool = false

  @Flag(help: "Alawys rebuild dependencies")
  var rebuildDependnecy: Bool = false

  @Option(help: "Specify build/cache directory")
  var buildPath: String = "./builder"

  @Flag(help: "Enable bitcode.")
  var enableBitcode: Bool = false
}
