import BuildSystem

public struct Handbrake: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.7.3"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/HandBrake/HandBrake.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/HandBrake/HandBrake/releases/download/\(version.toString())/HandBrake-\(version.toString())-source.tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .buildTool(Nasm.self),
        .buildTool(Meson.self),
        // TODO: should require python version > 3
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with context: BuildContext) throws {
    try context.launch(path: "./configure", ["--launch", "--launch-jobs=\(context.parallelJobs ?? 4)"])
  }
}
