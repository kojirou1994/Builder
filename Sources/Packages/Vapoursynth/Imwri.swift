import BuildSystem

public struct Imwri: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/vapoursynth/vs-imwri/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/vapoursynth/vs-imwri/archive/refs/tags/R\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Meson.self),
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(ImageMagick.self),
        .runTime(Libheif.self),
        .runTime(Vapoursynth.self),
        .runTime(Tiff.self),
      ],
      supportedLibraryType: .shared
    )
  }

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.meson("..")

      try context.make(toolType: .ninja, "install")
    }
  }
}
