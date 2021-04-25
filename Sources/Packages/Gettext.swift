import BuildSystem

public struct Gettext: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "0.21"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      throw PackageRecipeError.unsupportedVersion
    case .stable(let version):
      source = .tarball(url: "https://ftp.gnu.org/gnu/gettext/gettext-\(version.toString(includeZeroPatch: false)).tar.xz")
    }

    return .init(
      source: source
    )
  }

  public func build(with env: BuildEnvironment) throws {
    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      "--with-included-glib",
      "--with-included-libcroco",
      "--with-included-libunistring",
      "--with-included-libxml",
      "--with-emacs",
//      "--with-lispdir=#{elisp}",
      "--disable-java",
      "--disable-csharp",
//      # Don't use VCS systems to create these archives
      "--without-git",
      "--without-cvs",
      "--without-xz",
      "--with-included-gettext"
    )

    try env.make()

    try env.make(parallelJobs: 1, "install")
  }

}
