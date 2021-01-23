import BuildSystem

struct Ffms: Package {

  func build(with builder: Builder) throws {
    try builder.launch(path: "./autogen.sh")
    try builder.configure()

    try builder.make("install")
  }

  var source: PackageSource {
    .branch(repo: "https://github.com/FFMS/ffms2", revision: nil)
  }

  var dependencies: [Package] {
    [Ffmpeg.minimalDecoder]
  }

}
