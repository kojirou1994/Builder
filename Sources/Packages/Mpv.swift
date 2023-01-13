import BuildSystem

public struct Mpv: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.35"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/mpv-player/mpv.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/mpv-player/mpv/archive/v\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(PkgConfig.self),
        .buildTool(Python.self),
        .runTime(Ffmpeg.self),
        .runTime(Libarchive.self),
        .runTime(Ass.self),
        .runTime(Vapoursynth.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.launch(path: "bootstrap.py")

    try context.launch(
      path: "waf",
      "configure",
      "--prefix=\(context.prefix)"
    )

    try context.launch(path: "waf", "install")
  }

}
