import BuildSystem

struct Vorbis: Package {
  func build(with env: BuildEnvironment) throws {

    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(examples, "examples"),
      configureEnableFlag(docs, "docs"),
      configureEnableFlag(false, "oggtest"),
      "--with-ogg-libraries=\(env.dependencyMap[Ogg.self].lib.path)",
      "--with-ogg-includes=\(env.dependencyMap[Ogg.self].include.path)"
    )
    try env.make("install")
  }

  var source: PackageSource {
    .tarball(url: "https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz")
  }

  var dependencies: PackageDependency {
    .packages(Ogg.defaultPackage())
  }

  @Flag(inversion: .prefixedEnableDisable, help: "build the examples.")
  var examples: Bool = false

  @Flag(inversion: .prefixedEnableDisable, help: "build the documentation.")
  var docs: Bool = false

}
