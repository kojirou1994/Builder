struct FdkAac: Package {
  func build(with builder: Builder) throws {
    try builder.configure(
      builder.settings.library.buildStatic.configureFlag("static"),
      builder.settings.library.buildShared.configureFlag("shared"),
      example.configureFlag("example")
    )
    try builder.make("install")
  }

  var version: BuildVersion {
    .ball(url: URL(string: "https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-2.0.1.tar.gz")!, filename: nil)
  }
  
  @Flag(inversion: .prefixedEnableDisable, help: "Enable example encoding program.")
  var example: Bool = false

}
