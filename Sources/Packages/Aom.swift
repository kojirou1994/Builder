import BuildSystem

public struct Aom: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.2.0"
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

  public func build(with context: BuildContext) throws {

    try context.inRandomDirectory { _ in
      try context.cmake(
        toolType: .ninja,
        "..",
        cmakeOnFlag(false, "ENABLE_DOCS"),
        cmakeOnFlag(true, "ENABLE_EXAMPLES"),
        cmakeOnFlag(false, "ENABLE_TESTDATA"),
        cmakeOnFlag(false, "ENABLE_TESTS"),
        cmakeOnFlag(false, "ENABLE_TOOLS"),
        cmakeOnFlag(context.libraryType.buildShared, "BUILD_SHARED_LIBS"),
        (context.order.arch.isX86 || context.isBuildingNative) ? nil : cmakeDefineFlag(0, "CONFIG_RUNTIME_CPU_DETECT"),
        context.order.system == .watchOS ? cmakeDefineFlag("generic", "AOM_TARGET_CPU") : nil
      )

      try context.make(toolType: .ninja)
      try context.make(toolType: .ninja, "install")
    }

    try context.autoRemoveUnneedLibraryFiles()
  }

}
