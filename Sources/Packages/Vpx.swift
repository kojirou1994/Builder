import BuildSystem

public struct Vpx: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.10.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/webmproject/libvpx/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/webmproject/libvpx/archive/refs/tags/v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      supportedLibraryType: .static
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.changingDirectory(env.randomFilename) { _ in
      try env.launch(
        path: "../configure",
        "--prefix=\(env.prefix.root.path)",
        configureEnableFlag(false, CommonOptions.dependencyTracking),
        // shared won't compile, so always build static as default
        configureEnableFlag(false, "examples"),
        configureEnableFlag(false, "unit-tests"),
        configureEnableFlag(true, "pic"),
        configureEnableFlag(true, "vp9-highbitdepth")
      )

      try env.make()

      try env.make("install")
    }
  }

}
