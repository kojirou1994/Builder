import BuildSystem

struct P7Zip: Package {
  var version: PackageVersion {
    .stable("17.03")
  }

  var source: PackageSource {
    packageSource(for: version)!
  }

  func packageSource(for version: PackageVersion) -> PackageSource? {
    switch version {
    case .stable(let v):
      return .tarball(url: "https://github.com/jinfeihan57/p7zip/archive/v\(v).tar.gz", filename: "p7zip-\(v).tar.bz2")
    default:
      return nil
    }
  }

  func build(with env: BuildEnvironment) throws {

    try env.fm.removeItem(at: URL(fileURLWithPath: "makefile.machine"))
    try env.fm.copyItem(at: URL(fileURLWithPath: "makefile.macosx_llvm_64bits"), to: URL(fileURLWithPath: "makefile.machine"))
    try env.make("all3")
    try env.launch("make", "DEST_HOME=\(env.prefix.root.path)", "install")
//    system "make", "all3",
//    "CC=#{ENV.cc} $(ALLFLAGS)",
//    "CXX=#{ENV.cxx} $(ALLFLAGS)"
//    system "make", "DEST_HOME=#{prefix}",
//    "DEST_MAN=#{man}",
//    "install"
    /*
     cmake no install target
     https://github.com/jinfeihan57/p7zip/issues/116
     */
//    try env.changingDirectory("CPP/7zip/CMAKE/build", block: { _ in
//      try env.cmake(toolType: .ninja, "..")
//
//      try env.make(toolType: .ninja)
//      try env.make(toolType: .ninja, "install")
//    })

  }
}
