import BuildSystem

public struct Zlib: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.2.11"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/madler/zlib.git", requirement: .branch("develop"))
    case .stable(let version):
      source = .tarball(url: "https://zlib.net/zlib-\(version.toString()).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.launch(path: "configure",
                   "--prefix=\(env.prefix.root.path)",
                   env.order.target.arch.is64Bits ? "--64" : nil
    )
    
    try env.make()
    try env.make("install")
    try env.autoRemoveUnneedLibraryFiles()
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [.init(name: "zlib", content: """
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
