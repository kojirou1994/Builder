import BuildSystem

public struct Xml2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.9.10"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "http://xmlsoft.org/sources/libxml2-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: .init(packages: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Zlib.self),
      ])
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--without-python",
      "--without-lzma"
    )

    try env.make()

    try env.make("install")
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [
      .init(name: "libxml-2.0", content: """
        prefix=\(sdkPath)/usr
        exec_prefix=${prefix}
        libdir=${exec_prefix}/lib
        includedir=${prefix}/include
        modules=1

        Name: libXML
        Version: 2.9.4
        Description: libXML library version2.
        Requires:
        Libs: -L${libdir} -lxml2
        Libs.private:  -lpthread -L${libdir} -lz   -liconv -lm
        Cflags: -I${includedir}/libxml2
        """)
    ])
  }
}
