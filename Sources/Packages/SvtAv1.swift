import BuildSystem

public struct SvtAv1: Package {

  public init() {}

  @Flag(inversion: .prefixedEnableDisable)
  var apps: Bool = false

  public var defaultVersion: PackageVersion {
    "0.8.6"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/master/SVT-AV1-master.tar.gz")
    case .stable(let version):
      source = .tarball(url: "https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v\(version.toString())/SVT-AV1-v\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(Nasm.self),
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    // TODO: add BUILD_TESTING
    func build(shared: Bool) throws {

      let buildApps = apps && (env.libraryType != .all || (env.prefersStaticBin != shared))

      try env.changingDirectory(env.randomFilename) { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeOnFlag(false, "BUILD_SHARED_LIBS"),
          cmakeOnFlag(true, "ENABLE_NASM"),
          shared ? cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR") : nil,
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS", defaultEnabled: false),
          cmakeOnFlag(env.isBuildingNative, "NATIVE", defaultEnabled: false),
          cmakeOnFlag(buildApps, "BUILD_APPS")
        )

        try env.make(toolType: .ninja)
        try env.make(toolType: .ninja, "install")
      }
    }

    try build(shared: env.libraryType.buildShared)
    if env.libraryType == .all {
      try build(shared: false)
    }
  }

  public var tag: String {
    [
      apps ? "apps" : ""
    ].joined(separator: "_")
  }

}
