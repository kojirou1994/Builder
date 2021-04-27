import BuildSystem

public struct P7Zip: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "17.4.0"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/jinfeihan57/p7zip/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/jinfeihan57/p7zip/archive/refs/tags/v\(version.toString( includeZeroPatch: false, numberWidth: 2)).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with env: BuildEnvironment) throws {

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
//    try env.changingDirectory("CPP/7zip/CMAKE/build") { _ in
//      try env.cmake(toolType: .ninja, "..")
//
//      try env.make(toolType: .ninja)
//      try env.make(toolType: .ninja, "install")
//    })

  }
}
