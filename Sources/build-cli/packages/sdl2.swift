//struct Sdl2: Package {
//  func build(with env: BuildEnvironment) throws {
//    try env.configure(
//      env.libraryType.staticConfigureFlag,
//      env.libraryType.sharedConfigureFlag,
//      configureEnableFlag(false, CommonOptions.dependencyTracking),
//      false.configureEnableFlag("doc")
//    )
//    try env.make("install")
//  }
//
//  var version: BuildVersion {
//    .ball(url: URL(string: "https://libsdl.org/release/SDL2-2.0.14.tar.gz")!, filename: nil)
//  }
//}
