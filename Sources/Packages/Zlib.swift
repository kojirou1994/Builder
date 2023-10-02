import BuildSystem

public struct Zlib: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.3"
  }

  private func isLegacy(_ version: PackageVersion) -> Bool {
    version < "1.2.12"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/madler/zlib.git", requirement: .branch("develop"))
    case .stable(let version):
      source = .tarball(url: "https://zlib.net/zlib-\(version.toString(includeZeroPatch: false)).tar.gz")
    }

    let isLegacy = isLegacy(order.version)
    return .init(
      source: source,
      dependencies: [
        isLegacy ? nil : .buildTool(Cmake.self),
        isLegacy ? nil : .buildTool(Ninja.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    if isLegacy(context.order.version) {
      try context.launch(path: "configure",
                         "--prefix=\(context.prefix.root.path)",
                         context.order.arch.is64Bits ? "--64" : nil
      )

      try context.make()
      try context.make("install")
    } else {
      try context.inRandomDirectory { _ in
        try context.cmake(
          toolType: .ninja,
          "..",
          cmakeDefineFlag(context.prefix.pkgConfig.path, "INSTALL_PKGCONFIG_DIR"),
          nil
        )

        try context.make(toolType: .ninja)

        if context.canRunTests {
          try context.make(toolType: .ninja, "test")
        }

        try context.make(toolType: .ninja, "install")
      }
    }
    
    try context.autoRemoveUnneedLibraryFiles()
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    guard isLegacy(order.version) else {
      return nil
    }
    guard order.system.isApple else {
      return nil
    }
    return .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [.init(name: "zlib", content: """
      sdkPath=\(sdkPath)
      prefix=${sdkPath}/usr
      exec_prefix=/usr
      libdir=${exec_prefix}/lib
      sharedlibdir=${libdir}
      includedir=${prefix}/include

      Name: zlib
      Description: zlib compression library
      Version: 1.2.11

      Requires:
      Libs: -L${libdir} -L${sharedlibdir} -lz
      Cflags: -I${includedir}
      """)])
  }
}
