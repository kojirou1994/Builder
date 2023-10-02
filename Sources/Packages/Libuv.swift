import BuildSystem

public struct Libuv: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.46.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/libuv/libuv/archive/refs/heads/v1.x.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/libuv/libuv/archive/refs/tags/v\(version).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in

      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(false, "ASAN"), // Enable AddressSanitizer (ASan)
        cmakeOnFlag(context.strictMode, "BUILD_TESTING")
      )

      try context.make(toolType: .ninja)

      if context.canRunTests {
        try context.make(toolType: .ninja, "test")
      }

      try context.make(toolType: .ninja, "install")

      try context.moveItem(at: context.prefix.lib.appendingPathComponent("libuv_a.a"), to: context.prefix.lib.appendingPathComponent("libuv.a"))
      try context.removeItem(at: context.prefix.lib.appendingPathComponent("pkgconfig/libuv-static.pc"))

      try context.autoRemoveUnneedLibraryFiles()
    }
  }

}
