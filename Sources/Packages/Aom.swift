import BuildSystem

public struct Aom: Package {

  public init() {}

  @Flag(inversion: .prefixedEnableDisable)
  var examples: Bool = false

  public var defaultVersion: PackageVersion {
    "3.1.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://aomedia.googlesource.com/aom")
    case .stable(let version):
      source = .repository(url: "https://aomedia.googlesource.com/aom", requirement: .tag("v\(version.toString())"))
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Cmake.self),
        .buildTool(Ninja.self),
        .buildTool(Yasm.self)
      ],
      products: [
        .library(name: "aom", headers: ["aom"])
      ]
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try env.inRandomDirectory { _ in
      try env.cmake(
        toolType: .ninja,
        "..",
        cmakeDefineFlag(env.prefix.lib.path, "CMAKE_INSTALL_NAME_DIR"),
        cmakeOnFlag(false, "ENABLE_DOCS"),
        cmakeOnFlag(examples, "ENABLE_EXAMPLES"),
        cmakeOnFlag(false, "ENABLE_TESTDATA"),
        cmakeOnFlag(false, "ENABLE_TESTS"),
        cmakeOnFlag(false, "ENABLE_TOOLS"),
        cmakeOnFlag(env.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        (env.order.target.arch == .x86_64 || env.isBuildingNative) ? nil : cmakeDefineFlag(0, "CONFIG_RUNTIME_CPU_DETECT"),
        env.order.target.system == .watchOS ? cmakeDefineFlag("generic", "AOM_TARGET_CPU") : nil
      )

      try env.make(toolType: .ninja)
      try env.make(toolType: .ninja, "install")
    }

    try env.autoRemoveUnneedLibraryFiles()
  }

  public var tag: String {
    [
      examples ? "examples" : ""
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }

}
