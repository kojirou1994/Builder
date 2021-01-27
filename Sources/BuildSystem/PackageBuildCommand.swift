//import TSCBasic
//import TSCUtility
import Executable
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
        rebuildDependnecy: builderOptions.rebuildDependnecy, joinDependency: builderOptions.joinDependency, cleanAll: builderOptions.clean, deployTarget: deployTarget)

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

  @Option(help: "the library(.a) filename need to pack")
  var packXc: String?

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
          rebuildDependnecy: builderOptions.rebuildDependnecy, joinDependency: builderOptions.joinDependency, cleanAll: builderOptions.clean, deployTarget: nil)

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

    let fm = URLFileManager.default

    if let filename = packXc {
      if builtPackages.isEmpty {
        print("NOTHING TO PACK!")
        return
      }
      print("PACKING XCFRAMEWORK...")
      let output = "\(filename).xcframework"
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
        if package.value.count == 1 {
          libraryFileURL = package.value[0].prefix.lib.appendingPathComponent("\(filename).a")
            .resolvingSymlinksInPath()
        } else {
          let fatDirectory = lipoWorkingDirectory.appendingPathComponent("\(package.key)-\(package.value.map(\.arch.rawValue).joined(separator: "_"))")
          try retry(body: fm.createDirectory(at: fatDirectory))
          let fatOutput = fatDirectory.appendingPathComponent(filename + ".a")
          let lipoArguments = ["-create", "-output", fatOutput.path]
            + package.value.map { $0.prefix.lib.appendingPathComponent("\(filename).a").path }
          let lipo = AnyExecutable(executableName: "lipo",
                                       arguments: lipoArguments)
          try lipo.launch(use: TSCExecutableLauncher(outputRedirection: .none))
          libraryFileURL = fatOutput
        }
        args.append("-library")
        args.append(libraryFileURL.path)
        args.append("-headers")
        args.append(package.value[0].prefix.include.path)
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
}
