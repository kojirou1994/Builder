import BuildSystem

public struct Bzip2: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "1.0.8"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://sourceware.org/pub/bzip2/bzip2-\(version.toString()).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with env: BuildEnvironment) throws {

    try replace(contentIn: "Makefile", matching: "$(PREFIX)/man", with: "$(PREFIX)/share/man")

    try env.make("install",
                 "PREFIX=\(env.prefix.root.path)",
                 "CC=\(env.cc)")

//    try env.autoRemoveUnneedLibraryFiles()

    try env.fm.createDirectory(at: env.prefix.pkgConfig)
    try pkgConfig(prefix: env.prefix.root.path)
      .write(to: env.prefix.pkgConfig.appendingPathComponent("bzip2.pc"), atomically: true, encoding: .utf8)
  }

  private func pkgConfig(prefix: String) -> String {
    """
    prefix=\(prefix)
    exec_prefix=${prefix}
    libdir=${prefix}/lib
    includedir=${prefix}/include

    Name: bzip2
    Description: bzip2
    Version:
    Requires:
    Libs: -L${libdir} -lbz2
    Cflags: -I${includedir}
    """
  }

  public func systemPackage(for order: PackageOrder, sdkPath: String) -> SystemPackage? {
    .init(prefix: PackagePath(URL(fileURLWithPath: "/usr")), pkgConfigs: [
      .init(name: "bzip2", content: pkgConfig(prefix: sdkPath + "/usr"))
    ])
  }
}
