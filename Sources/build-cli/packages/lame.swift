import BuildSystem

struct Lame: Package {
  func build(with env: BuildEnvironment) throws {

    try replace(contentIn: "include/libmp3lame.sym", matching: "lame_init_old\n", with: "")

    try env.autoreconf()

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(true, "nasm")
    )

    try env.make("install")
  }

  var source: PackageSource {
    /*
     1.3.4 always fail?
     https://gitlab.xiph.org/xiph/ogg/-/issues/2298
     */
    .tarball(url: "https://netcologne.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz")
  }

}
