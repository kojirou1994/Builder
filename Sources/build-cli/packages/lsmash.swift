struct Lsmash: Package {
  func build(with builder: Builder) throws {
    if builder.settings.library.buildShared {
      // send warning
    }
    try builder.configure(
//      builder.settings.library.buildStatic.configureFlag("static", defaultEnabled: true)
//      builder.settings.library.buildShared.configureFlag("shared", defaultEnabled: false)
    )

    try builder.make(enableCli ? "install" : "install-lib")
  }

  var version: BuildVersion {
    .branch(repo: "https://github.com/l-smash/l-smash", revision: nil)
  }

  @Flag()
  var enableCli: Bool = false

}
