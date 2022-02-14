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

  public func build(with context: BuildContext) throws {

    func build(shared: Bool) throws {
      try context.changingDirectory(context.randomFilename) { _ in

        try context.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS", defaultEnabled: false)
        )

        try context.make(toolType: .ninja)
        //      try context.make(toolType: .ninja, "install")

        try context.mkdir(context.prefix.lib)
        try context.copyItem(at: URL(fileURLWithPath: "crypto/libcrypto.\(context.order.system.libraryExtension(shared: shared))"), toDirectory: context.prefix.lib)
        try context.copyItem(at: URL(fileURLWithPath: "ssl/libssl.\(context.order.system.libraryExtension(shared: shared))"), toDirectory: context.prefix.lib)
      }
    }

    try build(shared: context.libraryType.buildShared)
    if context.libraryType == .all {
      try build(shared: false)
    }

    try context.copyItem(at: URL(fileURLWithPath: "include"), toDirectory: context.prefix.root)

  }
}
