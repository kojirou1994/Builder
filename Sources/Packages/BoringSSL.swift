import BuildSystem

public struct BoringSSL: Package {

  public init() {}

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/google/boringssl/archive/master.zip")
    case .stable:
      throw PackageRecipeError.unsupportedVersion
    }

    return .init(
      source: source,
      dependencies: PackageDependencies(
        packages: .buildTool(Cmake.self),
        .buildTool(Go.self),
        .buildTool(Ninja.self)
      )
    )
  }

  public func build(with env: BuildEnvironment) throws {

    func build(shared: Bool) throws {
      try env.changingDirectory(env.randomFilename, block: { _ in

        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS", defaultEnabled: false)
        )

        try env.make(toolType: .ninja)
        //      try env.make(toolType: .ninja, "install")

        try env.fm.createDirectory(at: env.prefix.lib)
        try env.fm.copyItem(at: URL(fileURLWithPath: "crypto/libcrypto.\(env.target.system.libraryExtension(shared: shared))"), toDirectory: env.prefix.lib)
        try env.fm.copyItem(at: URL(fileURLWithPath: "ssl/libssl.\(env.target.system.libraryExtension(shared: shared))"), toDirectory: env.prefix.lib)
      })
    }

    try build(shared: env.libraryType.buildShared)
    if env.libraryType == .all {
      try build(shared: false)
    }

    try env.fm.copyItem(at: URL(fileURLWithPath: "include"), toDirectory: env.prefix.root)

  }
}
