import BuildSystem

public struct Nghttp2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.62.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/nghttp2/nghttp2/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/nghttp2/nghttp2/archive/refs/tags/v\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
//        .runTime(Openssl.self),
//        .runTime(Libev.self),
//        .runTime(Zlib.self),
//        .runTime(CAres.self),
//        .runTime(Xml2.self),
//        .runTime(Jemalloc.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try replace(contentIn: "src/shrpx_client_handler.cc", matching: "return dconn;", with: "return std::move(dconn);")

    try context.inRandomDirectory { _ in

      context.environment.append("-I\(context.prefix.include.path)", for: .cxxflags, .cflags)
      context.environment.append("-L\(context.prefix.lib.path)", for: .ldflags)

      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(false, "ENABLE_APP"),
        cmakeOnFlag(false, "ENABLE_HPACK_TOOLS"),
        cmakeOnFlag(false, "ENABLE_EXAMPLES"),
        cmakeOnFlag(context.libraryType.buildShared, "ENABLE_SHARED_LIB"),
        cmakeOnFlag(context.libraryType.buildStatic, "ENABLE_STATIC_LIB"),
        cmakeOnFlag(false, "ENABLE_HTTP3"),
        cmakeOnFlag(false, "ENABLE_DOC")
      )

      try context.make(toolType: .ninja, "lib/install")

      try context.make(toolType: .ninja, "install")
    }
  }

}
