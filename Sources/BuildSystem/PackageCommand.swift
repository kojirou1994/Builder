import TSCBasic
import TSCUtility

public struct PackageCommand<T: Package>: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(commandName: T.name,
          abstract: "", discussion: "",
          version: "")
  }

  public init() {}

  @Option(name: .shortAndLong, help: "Library type, available: \(PackageLib.allCases.map(\.rawValue).joined(separator: ", "))")
  var library: PackageLib = .statik

  @Option(help: "Customize the package version, if supported.")
  var version: String?

  @Flag()
  var skipDependencies: Bool = false

  @Flag()
  var skipClean: Bool = false

  @Flag()
  var info: Bool = false

  @Option(help: "Specify build/cache directory")
  var buildPath: String = "./builder"

  @OptionGroup
  var package: T

  public mutating func run() throws {
    if info {
      print(package)
    } else {
      // repositories
      // checkouts
      let builderDirectoryURL = URL(fileURLWithPath: buildPath)
      let workingRootDirectoryURL = builderDirectoryURL.appendingPathComponent("working")
      let downloadCacheDirectory = builderDirectoryURL.appendingPathComponent("download")
      let productsDirectoryURL = builderDirectoryURL.appendingPathComponent("products")

      var builder = Builder(
        settings: .init(prefix: productsDirectoryURL.path,
                        library: library),
        srcRootDirectoryURL: workingRootDirectoryURL,
        productsDirectoryURL: productsDirectoryURL,
        downloadCacheDirectory: downloadCacheDirectory)

      try ProcessEnv.setVar("PKG_CONFIG_PATH", value: productsDirectoryURL.appendingPathComponent("lib")
                              .appendingPathComponent("pkgconfig").path)

      let oldPATH = ProcessEnv.path ?? ""
      let newPATH = productsDirectoryURL.appendingPathComponent("bin").path + ":" + oldPATH
      try ProcessEnv.setVar("PATH", value: newPATH)

      try builder.startBuild(package: package, version: version)
    }
  }
}

extension Builder {
  mutating func startBuild(package: Package, version: String?) throws {
    builtPackages = .init()
    defer {
      builtPackages = .init()
    }
    try? removeItem(at: productsDirectoryURL)
    try? removeItem(at: srcRootDirectoryURL)
    
    try mkdir(downloadCacheDirectory)

    try buildDeps(package: package, buildSelf: false)

    try build(package: package, version: version)
  }

  private mutating func buildDeps(package: Package,
                                  buildSelf: Bool) throws {
    let deps = package.dependencies
    print("Building \(package.name)")
    if !deps.isEmpty {
      print("Dependencies:", deps.map(\.name).joined(separator: ", "))
      try deps.forEach { dependency in
        try buildDeps(package: dependency, buildSelf: true)
      }
    }
    if buildSelf {
      try build(package: package)
      builtPackages.insert(package.name)
    }
  }
}

//extension Version: ExpressibleByArgument {
//  public init?(argument: String) {
//    self.init(string: argument)
//  }
//}
