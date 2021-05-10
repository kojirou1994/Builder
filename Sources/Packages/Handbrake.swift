import BuildSystem

public struct Handbrake: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.3"
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
        .pip(["meson"]),
        // TODO: should require python version > 3
      ],
      supportedLibraryType: nil
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.launch(path: "configure", ["--launch", "--launch-jobs=\(env.parallelJobs ?? 4)"])
  }
}
