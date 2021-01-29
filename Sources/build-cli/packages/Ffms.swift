import BuildSystem

struct Ffms: Package {

  func build(with env: BuildEnvironment) throws {
    try env.launch(path: "./autogen.sh")
    try env.configure()

    try env.make("install")
  }

  var source: PackageSource {
    .branch(repo: "https://github.com/FFMS/ffms2", revision: nil)
  }

  var dependencies: PackageDependency {
    .packages(Ffmpeg.minimalDecoder)
  }

}
