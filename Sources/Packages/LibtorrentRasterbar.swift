import BuildSystem

public struct LibtorrentRasterbar: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.2.18"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/arvidn/libtorrent.git")
    case .stable(let version):
      source = .tarball(url: "https://github.com/arvidn/libtorrent/releases/download/v\(version.toString(includeZeroMinor: false))/libtorrent-rasterbar-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .runTime(Boost.self),
        .runTime(Openssl.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        cmakeOnFlag(context.order.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        cmakeOnFlag(context.strictMode, "build_tests"),
        ".."
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }
  }
}
