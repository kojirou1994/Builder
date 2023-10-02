import BuildSystem

public struct Libssh: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.9.7"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://git.libssh.org/projects/libssh.git")
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://www.libssh.org/files/0.9/libssh-\(versionString).tar.xz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(PkgConfig.self),
        .runTime(Openssl.self),
        .runTime(Zlib.self),
      ],
      products: [
        .library(name: "ssh", headers: ["libssh"]),
      ],
      canBuildAllLibraryTogether: false
    )
  }

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in

      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS")
      )

      try context.make(toolType: .ninja)

      if context.canRunTests {
//        try context.make(toolType: .ninja, "test")
      }

      try context.make(toolType: .ninja, "install")
    }
  }
}
