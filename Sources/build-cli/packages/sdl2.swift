//struct Sdl2: Package {
//  func build(with builder: Builder) throws {
//    try builder.configure(
//      builder.settings.library.buildStatic.configureFlag("static"),
//      builder.settings.library.buildShared.configureFlag("shared"),
//      false.configureFlag("dependency-tracking"),
//      false.configureFlag("doc")
//    )
//    try builder.make("install")
//  }
//
//  var version: BuildVersion {
//    .ball(url: URL(string: "https://libsdl.org/release/SDL2-2.0.14.tar.gz")!, filename: nil)
//  }
//}
