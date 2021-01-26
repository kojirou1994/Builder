//import TSCBasic
//import TSCUtility

public struct PackageCommand<T: Package>: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(commandName: T.name,
          abstract: "", discussion: "",
          version: "")
  }

  public init() {}

  @Option(name: .shortAndLong, help: "Library type, available: \(PackageLibraryBuildType.allCases.map(\.rawValue).joined(separator: ", "))")
  var library: PackageLibraryBuildType = .statik

  @Option(help: "Customize the package version, if supported.")
  var version: String?

  @Flag(help: "Clean all built packages")
  var clean: Bool = false

  @Flag(help: "Alawys rebuild dependencies")
  var rebuildDependnecy: Bool = false

  @Flag()
  var info: Bool = false

  @Option(help: "Specify build/cache directory")
  var buildPath: String = "./builder"

  @Option()
  var arch: BuildArch = .native

  @Option()
  var system: BuildTargetSystem = .native

  @Option(help: "Set target system version.")
  var deployTarget: String?

  @OptionGroup
  var package: T

  public mutating func run() throws {
    if info {
      print(package)
    } else {
      let builder = try Builder(
        builderDirectoryURL: URL(fileURLWithPath: buildPath),
        cc: "clang", cxx: "clang++",
        libraryType: library, target: .init(arch: arch, system: system),
        rebuildDependnecy: rebuildDependnecy, cleanAll: clean, deployTarget: deployTarget)

      try builder.startBuild(package: package, version: version)
    }
  }
}
