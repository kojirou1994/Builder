import BuildSystem

public struct Xslt: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("1.1.34")
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "http://xmlsoft.org/sources/libxslt-\(version.toString()).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Xml2.self),
        .runTime(Gcrypt.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag,
      "--without-python",
      nil
    )

    try context.make()

    try context.make("install")
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [
      .init(name: "libxslt", content: """
        prefix=\(sdkPath)/usr
        exec_prefix=${prefix}
        libdir=${exec_prefix}/lib
        includedir=${prefix}/include

        Name: libxslt
        Version: 1.1.29
        Description: XSLT library version 2.
        Requires: libxml-2.0
        Cflags: -I${includedir}
        Libs: -L${libdir} -lxslt
        Libs.private:
        """),
      .init(name: "libexslt", content: """
        prefix=\(sdkPath)/usr
        exec_prefix=${prefix}
        libdir=${exec_prefix}/lib
        includedir=${prefix}/include

        Name: libexslt
        Version: 0.8.17
        Description: EXSLT Extension library
        Requires: libxml-2.0
        Cflags: -I${includedir}
        Libs: -L${libdir} -lexslt -lxslt
        """)
    ])
  }
}
