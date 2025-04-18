import BuildSystem

public struct Openssl: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "3.4.1"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {

    let source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/openssl/openssl")
    case .stable(let version):
      var versionString = version.toString(includeZeroMinor: true, includeZeroPatch: true, includePrerelease: false, includeBuildMetadata: false)
      if !version.prereleaseIdentifiers.isEmpty {
        versionString += "-"
        versionString += version.prereleaseIdentifiers.joined(separator: ".")
      } else if !version.buildMetadataIdentifiers.isEmpty {
        versionString += version.buildMetadataIdentifiers.joined(separator: ".")
      }
      source = .tarball(url: "https://www.openssl.org/source/openssl-\(versionString).tar.gz")
    }

    return .init(
      source: source
    )
  }

  public func build(with context: BuildContext) throws {

    let os: String// = "\(context.order.system.openssl)-\(context.order.arch.clangTripleString)"
    switch context.order.system {
    case .macOS, .macCatalyst,
         .iphoneOS, .iphoneSimulator,
         .watchOS, .watchSimulator,
         .tvOS, .tvSimulator:
      os = "darwin\(context.order.arch.is64Bits ? "64" : "")-\(context.order.arch.clangTripleString)-cc"
    case .linuxGNU:
      //"linux-x86_64-clang"
      os = "linux-\(context.order.arch.gnuTripleString)"
    }
    /*
     pick os/compiler from:
     BS2000-OSD BSD-generic32 BSD-generic64 BSD-ia64 BSD-sparc64 BSD-sparcv8
     BSD-x86 BSD-x86-elf BSD-x86_64 Cygwin Cygwin-i386 Cygwin-i486 Cygwin-i586
     Cygwin-i686 Cygwin-x86 Cygwin-x86_64 DJGPP MPE/iX-gcc UEFI UWIN VC-CE VC-WIN32
     VC-WIN32-ARM VC-WIN32-ONECORE VC-WIN64-ARM VC-WIN64A VC-WIN64A-ONECORE
     VC-WIN64A-masm VC-WIN64I aix-cc aix-gcc aix64-cc aix64-gcc android-arm
     android-arm64 android-armeabi android-mips android-mips64 android-x86
     android-x86_64 android64 android64-aarch64 android64-mips64 android64-x86_64
     bsdi-elf-gcc cc darwin-i386-cc darwin-ppc-cc darwin64-arm64-cc darwin64-ppc-cc
     darwin64-x86_64-cc gcc haiku-x86 haiku-x86_64 hpux-ia64-cc hpux-ia64-gcc
     hpux-parisc-cc hpux-parisc-gcc hpux-parisc1_1-cc hpux-parisc1_1-gcc
     hpux64-ia64-cc hpux64-ia64-gcc hpux64-parisc2-cc hpux64-parisc2-gcc hurd-x86
     ios-cross ios-xcrun ios64-cross ios64-xcrun iossimulator-xcrun iphoneos-cross
     irix-mips3-cc irix-mips3-gcc irix64-mips4-cc irix64-mips4-gcc linux-aarch64
     linux-alpha-gcc linux-aout linux-arm64ilp32 linux-armv4 linux-c64xplus
     linux-elf linux-generic32 linux-generic64 linux-ia64 linux-mips32 linux-mips64
     linux-ppc linux-ppc64 linux-ppc64le linux-sparcv8 linux-sparcv9 linux-x32
     linux-x86 linux-x86-clang linux-x86_64 linux-x86_64-clang linux32-s390x
     linux64-mips64 linux64-s390x linux64-sparcv9 mingw mingw64 nextstep
     nextstep3.3 sco5-cc sco5-gcc solaris-sparcv7-cc solaris-sparcv7-gcc
     solaris-sparcv8-cc solaris-sparcv8-gcc solaris-sparcv9-cc solaris-sparcv9-gcc
     solaris-x86-gcc solaris64-sparcv9-cc solaris64-sparcv9-gcc solaris64-x86_64-cc
     solaris64-x86_64-gcc tru64-alpha-cc tru64-alpha-gcc uClinux-dist
     uClinux-dist64 unixware-2.0 unixware-2.1 unixware-7 unixware-7-gcc vms-alpha
     vms-alpha-p32 vms-alpha-p64 vms-ia64 vms-ia64-p32 vms-ia64-p64 vos-gcc
     vxworks-mips vxworks-ppc405 vxworks-ppc60x vxworks-ppc750 vxworks-ppc750-debug
     vxworks-ppc860 vxworks-ppcgen vxworks-simlinux
     */
//    let os = "darwin64-arm64-cc"

    try context.launch(
      path: "./Configure",
      "--prefix=\(context.prefix.root.path)",
      "--openssldir=\(context.prefix.appending("etc", "openssl").path)",
      context.libraryType.buildShared ? "shared" : "no-shared",
      context.canRunTests ? nil : "no-tests",
      os,
      context.order.arch.is64Bits ? "enable-ec_nistp_64_gcc_128" : nil
    )

    try context.make()
    if context.canRunTests {
      try context.make("test")
    }
    try context.make("install")
    if context.libraryType == .shared {
      try context.autoRemoveUnneedLibraryFiles()
    }
  }

  @Flag
  var noDepreacated: Bool = false

  @Flag
  var noAsync: Bool = false
}

fileprivate extension TargetSystem {
  var openssl: String {
    switch self {
    case .iphoneOS: return "ios-cross"
    case .iphoneSimulator: return "ios-sim-cross"
    case .linuxGNU: return "linux"
    case .macCatalyst: return "mac-catalyst"
    case .macOS: return "macos"
    case .tvOS: return "tvos-cross"
    case .tvSimulator: return "tvos-sim-cross"
    case .watchOS: return "watchos-cross"
    case .watchSimulator: return "watchos-sim-cross"
    }
  }
}
