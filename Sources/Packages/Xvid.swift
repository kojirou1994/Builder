import BuildSystem

public struct Xvid: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3.7"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://downloads.xvid.com/downloads/xvidcore-\(version.toString()).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      products: [
        .library(name: "xvidcore", headers: ["xvid.h"]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try context.changingDirectory("build/generic") { _ in
      try context.launch(path: "bootstrap.sh")

      try context.fixAutotoolsForDarwin()

      try context.configure()

      try context.make()

      try context.make("install")
      let sharedLibraryExtension = context.order.system.sharedLibraryExtension
      try FileManager.default.createSymbolicLink(atPath: context.prefix.lib.appendingPathComponent("libxvidcore.\(sharedLibraryExtension)").path, withDestinationPath: "libxvidcore.4.\(sharedLibraryExtension)")

      try context.autoRemoveUnneedLibraryFiles()
    }

  }

}
