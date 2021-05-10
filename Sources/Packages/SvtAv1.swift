import BuildSystem

fileprivate let lastArmInvalidVersion: PackageVersion = "0.8.6"

fileprivate let repoSource = PackageSource.repository(url: "https://gitlab.com/AOMediaCodec/SVT-AV1.git")

public struct SvtAv1: Package {

  public init() {}

  @Flag(inversion: .prefixedEnableDisable, help: "Disable apps to build for other systems")
  var apps: Bool = true

  public var defaultVersion: PackageVersion {
    "0.8.6"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    if order.target.arch.isARM, order.version < lastArmInvalidVersion {
      // only head can compile for arm...
      source = repoSource
    } else {
      switch order.version {
      case .head:
        source = repoSource
      case .stable(let version):
        source = .tarball(url: "https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v\(version.toString())/SVT-AV1-v\(version.toString()).tar.gz")
      }
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        order.target.arch.isX86 ? .buildTool(Yasm.self) : nil,
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    let compileCOnly: String?
    if env.order.version > lastArmInvalidVersion {
      compileCOnly = nil
    } else {
      compileCOnly = cmakeOnFlag(!env.order.target.arch.isX86, "COMPILE_C_ONLY")
    }

    func build(shared: Bool) throws {

      try env.inRandomDirectory { _ in
        try env.cmake(
          toolType: .ninja,
          "..",
          cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS"),
          cmakeOnFlag(env.isBuildingNative, "NATIVE"),
          compileCOnly,
//          cmakeOnFlag(env.strictMode, "BUILD_TESTING"), // tests can't compile!
          cmakeOnFlag(apps, "BUILD_APPS")
        )

        try env.make(toolType: .ninja)
        if env.canRunTests {
//          try env.make(toolType: .ninja, "test")
        }
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
      apps ? "" : "no-apps"
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }

}
