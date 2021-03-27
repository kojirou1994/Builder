import BuildSystem

struct Ffms: Package {

  func build(with env: BuildEnvironment) throws {
    try env.launch(path: "./autogen.sh")
    try env.configure()

    try env.make("install")
  }

  var source: PackageSource {
    .repository(url: "https://github.com/FFMS/ffms2", requirement: .branch("master"))
  }

  func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(.init(Ffmpeg.minimalDecoder))
  }

}
