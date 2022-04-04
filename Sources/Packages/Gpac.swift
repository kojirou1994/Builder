import BuildSystem

public struct Gpac: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "2.0.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/gpac/gpac.git")
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://github.com/gpac/gpac/archive/refs/tags/v\(versionString).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(PkgConfig.self),
        .runTime(Openssl.self),
        .runTime(Zlib.self),
        .runTime(Ogg.self),
        .runTime(Xz.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {

    try replace(contentIn: "configure", matching: "alt_macosx_dir=\"/opt/local\"", with: "alt_macosx_dir=\"\"")
    try replace(contentIn: "configure", matching: "CFLAGS_DIR=\"-I/opt/local/include $CFLAGS_DIR\"", with: "")
    try replace(contentIn: "configure", matching: "LDFLAGS=\"-L/opt/local/lib $LDFLAGS\"", with: "")

    try context.inRandomDirectory { _ in
      try context.configure(
        directory: "..",
        context.libraryType == .static ? "--static-mp4box" : nil,
//        "--disable-wx",
//        "--disable-pulseaudio",
//        "--disable-x11"
        "--extra-cflags=-Wno-deprecated"
      )

      try context.make()
      try context.make("install")
    }
  }
}
