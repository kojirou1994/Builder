import BuildSystem

public struct Dvdread: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "6.1.2"
  }

  @Flag(inversion: .prefixedEnableDisable)
  var dvdcss: Bool = false

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://download.videolan.org/pub/videolan/libdvdread/\(version.toString())/libdvdread-\(version.toString()).tar.bz2")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        dvdcss ? .runTime(Dvdcss.self) : nil,
      ],
      products: [.library(name: "libdvdread", headers: ["dvdread"])]
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureWithFlag(dvdcss, "libdvdcss")
    )

    try env.make()
    try env.make("install")
  }

  public var tag: String {
    [
      dvdcss ? "DVDCSS" : ""
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "_")
  }

}
