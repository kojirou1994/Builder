import BuildSystem

struct Lsmash: Package {
  func build(with env: BuildEnvironment) throws {
    if env.libraryType.buildShared {
      // send warning
    }
    try env.configure(
//      env.libraryType.buildStatic.configureEnableFlag("static", defaultEnabled: true)
//      env.libraryType.buildShared.configureEnableFlag("shared", defaultEnabled: false)
    )

    try env.make(enableCli ? "install" : "install-lib")
  }

  var source: PackageSource {
    .branch(repo: "https://github.com/l-smash/l-smash", revision: nil)
  }

  @Flag()
  var enableCli: Bool = false

}
