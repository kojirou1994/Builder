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
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Go.self),
        .buildTool(Ninja.self)
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    func build(shared: Bool) throws {
      try env.changingDirectory(env.randomFilename) { _ in

        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS", defaultEnabled: false)
        )

        try env.make(toolType: .ninja)
        //      try env.make(toolType: .ninja, "install")

        try env.mkdir(env.prefix.lib)
        try env.copyItem(at: URL(fileURLWithPath: "crypto/libcrypto.\(env.order.target.system.libraryExtension(shared: shared))"), toDirectory: env.prefix.lib)
        try env.copyItem(at: URL(fileURLWithPath: "ssl/libssl.\(env.order.target.system.libraryExtension(shared: shared))"), toDirectory: env.prefix.lib)
      }
    }

    try build(shared: env.libraryType.buildShared)
    if env.libraryType == .all {
      try build(shared: false)
    }

    try env.copyItem(at: URL(fileURLWithPath: "include"), toDirectory: env.prefix.root)

  }
}
