import TSCBasic

struct PackageCommand<T: Package>: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(commandName: T.name,
          abstract: "", discussion: "",
          version: "")
  }

  @Option(name: .shortAndLong, help: "Library type")
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

  mutating func run() throws {
    // repositories
    // checkouts
    let builderDirectoryURL = URL(fileURLWithPath: buildPath)
    let workingRootDirectoryURL = builderDirectoryURL.appendingPathComponent("working")
    let downloadCacheDirectory = builderDirectoryURL.appendingPathComponent("download")
    let productsDirectoryURL = builderDirectoryURL.appendingPathComponent("products")

    let builder = Builder(
      settings: .init(prefix: productsDirectoryURL.path,
                      library: library),
      srcRootDirectoryURL: workingRootDirectoryURL,
      productsDirectoryURL: productsDirectoryURL,
      downloadCacheDirectory: downloadCacheDirectory)

    try ProcessEnv.setVar("PKG_CONFIG_PATH", value: productsDirectoryURL.appendingPathComponent("lib")
                          .appendingPathComponent("pkgconfig").path)

    try builder.startBuild(package: package)
  }
}

extension Builder {
  func startBuild(package: Package) throws {
//    builtPackages = .init()
//    defer {
//      builtPackages = .init()
//    }
    try? removeItem(at: productsDirectoryURL)
    try mkdir(downloadCacheDirectory)

    try buildPackageAndDeps(package: package)
  }

  private func buildPackageAndDeps(package: Package) throws {
    let deps = package.dependencies
    print("Building \(package.name)")
    if !deps.isEmpty {
      print("Dependencies:", deps.map(\.name).joined(separator: ", "))
      try deps.forEach { dependency in
        try buildPackageAndDeps(package: dependency)
      }
    }
    try build(package: package)
  }
}
