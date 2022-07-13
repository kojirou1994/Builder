import BuildSystem

fileprivate let lastArmInvalidVersion: PackageVersion = "0.8.7"

fileprivate let repoSource = PackageSource.repository(url: "https://gitlab.com/AOMediaCodec/SVT-AV1.git")

public struct SvtAv1: Package {

  public init() {}

  @Flag(inversion: .prefixedEnableDisable, help: "Disable apps to build for other systems")
  var apps: Bool = true

  public var defaultVersion: PackageVersion {
    "1.1.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    if order.arch.isARM, order.version <= lastArmInvalidVersion {
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
        order.arch.isX86 ? .buildTool(Yasm.self) : nil,
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    let compileCOnly: String?
    if context.order.version > lastArmInvalidVersion {
      compileCOnly = nil
    } else {
      compileCOnly = cmakeOnFlag(!context.order.arch.isX86, "COMPILE_C_ONLY")
    }

    func build(shared: Bool) throws {

      try context.inRandomDirectory { _ in
        try context.cmake(
          toolType: .ninja,
          "..",
          cmakeDefineFlag(context.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
          cmakeOnFlag(shared, "BUILD_SHARED_LIBS"),
          cmakeOnFlag(context.isBuildingNative, "NATIVE"),
          compileCOnly,
//          cmakeOnFlag(context.strictMode, "BUILD_TESTING"), // tests can't compile!
          cmakeOnFlag(apps, "BUILD_APPS")
        )

        try context.make(toolType: .ninja)
        if context.canRunTests {
//          try context.make(toolType: .ninja, "test")
        }
        try context.make(toolType: .ninja, "install")
      }
    }

    try build(shared: context.libraryType.buildShared)
    if context.libraryType == .all {
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
