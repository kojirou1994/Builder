import BuildSystem
import Precondition

public struct ImageMagick: Package {

  enum QuantumDepth: UInt8, ExpressibleByArgument, CustomStringConvertible, CaseIterable {
    case k8 = 8
    case k16 = 16
    case k32 = 32

    var description: String { rawValue.description }
  }

  @Option(help: "Available: \(QuantumDepth.allCases.map(\.description).joined(separator: ", "))")
  var quantumDepth: QuantumDepth = .k16

  public static var name: String { "imagemagick" }

  public init() {}

  public var defaultVersion: PackageVersion {
    .stable("7.0.11-8")
  }

  public var tag: String {
    [
      quantumDepth != .k16 ? quantumDepth.description : "",
    ]
    .joined(separator: "_")
  }

  public func stablePackageSource(for version: Version) -> PackageSource? {
    .tarball(url: "https://download.imagemagick.org/ImageMagick/download/releases/ImageMagick-\(version.toString()).tar.xz")
  }

  public func build(with env: BuildEnvironment) throws {
//    try env.autoreconf()
//    var libs = [
//      "-ljpeg",
//    ]

//    if env.libraryType == .shared {
//      libs.append("-rpath")
//      libs.append(env.dependencyMap[Mozjpeg.self].lib.path)
//    }

    try env.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      "--with-quantum-depth=\(quantumDepth.rawValue)",
      env.libraryType.staticConfigureFlag,
      env.libraryType.sharedConfigureFlag,
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      configureEnableFlag(true, "opencl"),
      configureEnableFlag(false, "deprecated"),
      configureWithFlag(env.libraryType.buildShared, "modules"), // Modules may only be built if building shared libraries is enabled.
      configureWithFlag(true, "freetype"),
      configureWithFlag(true, "webp"),
      configureWithFlag(false, "magick-plus-plus"),
      configureWithFlag(true, "jxl"),
      configureWithFlag(false, "openexr"),
//      "CFLAGS=\(env.environment["CFLAGS", default: ""])",
//      "LDFLAGS=\(env.environment["LDFLAGS", default: ""])",
//      "JPEG_DELEGATE_TRUE=1"
//      "LIBS=\(libs.joined(separator: " "))",
      nil
    )

    try env.make()
    try env.make("install")
  }


  public func dependencies(for version: PackageVersion) -> PackageDependencies {
    .packages(
      .init(Webp.self),
      .init(Freetype.self),
      .init(JpegXL.self),
      .init(Openexr.self),
      .init(Mozjpeg.self),
      .init(Xz.self)
    )
  }
}
//# Avoid references to shim
//inreplace Dir["**/*-config.in"], "@PKG_CONFIG@", Formula["pkg-config"].opt_bin/"pkg-config"
//
//args = %W[
//--enable-osx-universal-binary=no

//--with-gvc=no
//--with-openjp2
//--with-heic=yes
//--with-gslib
//--with-gs-font-dir=#{HOMEBREW_PREFIX}/share/ghostscript/fonts
//--with-lqr
//--without-fftw
//--without-pango
//--without-wmf
//--enable-openmp
//ac_cv_prog_c_openmp=-Xpreprocessor\ -fopenmp
//ac_cv_prog_cxx_openmp=-Xpreprocessor\ -fopenmp
//LDFLAGS=-lomp\ -lz
//]
//
//on_macos do
//args << "--without-x"
//end
//
//# versioned stuff in main tree is pointless for us
//inreplace "configure", "${PACKAGE_NAME}-${PACKAGE_BASE_VERSION}", "${PACKAGE_NAME}"
//system "./configure", *args
//system "make", "install"
/*
 Optional Features:
 --disable-option-checking  ignore unrecognized --enable/--with options
 --disable-FEATURE       do not include FEATURE (same as --enable-FEATURE=no)
 --enable-FEATURE[=ARG]  include FEATURE [ARG=yes]
 --enable-silent-rules   less verbose build output (undo: "make V=1")
 --disable-silent-rules  verbose build output (undo: "make V=0")
 --enable-dependency-tracking
 do not reject slow dependency extractors
 --disable-dependency-tracking
 speeds up one-time build
 --enable-ld-version-script
 enable linker version script (default is enabled
 when possible)
 --enable-bounds-checking
 enable run-time bounds-checking
 --enable-osx-universal-binary
 build universal binary on OS X [[default=no]]
 --disable-openmp        do not use OpenMP
 --enable-opencl         use OpenCL
 --disable-largefile     omit support for large files
 --enable-shared[=PKGS]  build shared libraries [default=yes]
 --enable-static[=PKGS]  build static libraries [default=yes]
 --enable-fast-install[=PKGS]
 optimize for fast installation [default=yes]
 --disable-libtool-lock  avoid locking (might break parallel builds)
 --enable-delegate-build look for delegate libraries in build directory
 --disable-deprecated    exclude deprecated methods in MagickCore and
 MagickWand APIs
 --disable-installed     Formally install ImageMagick under PREFIX
 --disable-cipher        disable enciphering and deciphering image pixels
 --enable-zero-configuration
 enable self-contained, embeddable,
 zero-configuration ImageMagick
 --enable-hdri           accurately represent the wide range of intensity
 levels found in real scenes
 --enable-pipes          enable pipes (|) in filenames
 --disable-assert        disable assert() statements in build
 --enable-maintainer-mode
 enable make rules and dependencies not useful (and
 sometimes confusing) to the casual installer
 --enable-hugepages      enable 'huge pages' support
 --enable-ccmalloc       enable 'ccmalloc' memory debug support
 --enable-efence         enable 'efence' memory debug support
 --enable-prof           enable 'prof' profiling support
 --enable-gprof          enable 'gprof' profiling support
 --enable-gcov           enable 'gcov' profiling support
 --enable-legacy-support install legacy command-line utilities (default disabled)
 --disable-assert        turn off assertions
 --disable-docs          disable building of documentation

 Optional Packages:
 --with-PACKAGE[=ARG]    use PACKAGE [ARG=yes]
 --without-PACKAGE       do not use PACKAGE (same as --with-PACKAGE=no)
 --with-gnu-ld           assume the C compiler uses GNU ld [default=no]
 --with-dmalloc          use dmalloc, as in http://www.dmalloc.com
 --with-gcc-arch=<arch>  use architecture <arch> for gcc -march/-mtune,
 instead of guessing
 --includearch-dir=DIR   ARCH specific include directory
 --sharearch-dir=DIR     ARCH specific config directory
 --with-pkgconfigdir=DIR Path to the pkgconfig directory [LIBDIR/pkgconfig]
 --without-threads       disable POSIX threads API support
 --with-pic[=PKGS]       try to use only PIC/non-PIC objects [default=use
 both]
 --with-aix-soname=aix|svr4|both
 shared library versioning (aka "SONAME") variant to
 provide on AIX, [default=aix].
 --with-sysroot[=DIR]    Search for dependent libraries within DIR (or the
 compiler's sysroot if not specified).
 --with-modules          enable building dynamically loadable modules
 --with-method-prefix=PREFIX
 prefix MagickCore API methods
 --with-utilities  enable building command-line utilities (default yes)
 --with-quantum-depth=DEPTH
 number of bits in a pixel quantum (default 16)
 --with-cache=THRESHOLD  set pixel cache threshhold in MB (default available
 memory)
 --with-frozenpaths      freeze delegate paths
 --without-magick-plus-plus
 disable build/install of Magick++
 --with-package-release-name=NAME
 encode this name into the shared library
 --with-perl             enable build/install of PerlMagick
 --with-perl-options=OPTIONS
 options to pass on command-line when generating
 PerlMagick build file
 --with-jemalloc         enable jemalloc memory allocation library support
 --with-tcmalloc         enable tcmalloc memory allocation library support
 --with-umem             enable umem memory allocation library support
 --with-libstdc=DIR      use libstdc++ in DIR (for GNU C++)
 --without-bzlib         disable BZLIB support
 --with-x                use the X Window System
 --without-zip           disable ZIP support
 --without-zlib          disable ZLIB support
 --without-zstd          disable ZSTD support
 --with-apple-font-dir=DIR
 Apple font directory
 --with-autotrace        enable autotrace support
 --without-dps           disable Display Postscript support
 --with-dejavu-font-dir=DIR
 DejaVu font directory
 --with-fftw             enable FFTW support
 --without-flif          disable FLIF support
 --without-fpx           disable FlashPIX support
 --without-djvu          disable DjVu support
 --without-fontconfig    disable fontconfig support
 --without-freetype      disable Freetype support
 --without-raqm          disable Raqm support
 --without-gdi32         disable Windows gdi32 support
 --with-gslib            enable Ghostscript library support
 --with-fontpath=DIR     prepend to default font search path
 --with-gs-font-dir=DIR  Ghostscript font directory
 --with-gvc              enable GVC support
 --without-heic          disable HEIC support
 --without-jbig          disable JBIG support
 --without-jpeg          disable JPEG support
 --with-jxl              enable JPEG-XL support
 --without-lcms          disable lcms (v1.1X) support
 --without-openjp2       disable OpenJP2 support
 --without-lqr           disable Liquid Rescale support
 --without-lzma          disable LZMA support
 --without-openexr       disable OpenEXR support
 --without-pango         disable PANGO support
 --without-png           disable PNG support
 --without-raw           disable Raw support
 --with-rsvg             enable RSVG support
 --without-tiff          disable TIFF support
 --with-urw-base35-font-dir=DIR
 URW-base35 font directory
 --without-webp          disable WEBP support
 --with-windows-font-dir=DIR
 Windows font directory
 --with-wmf              enable WMF support
 --without-xml           disable XML support

 Some influential environment variables:
 CC          C compiler command
 CFLAGS      C compiler flags
 LDFLAGS     linker flags, e.g. -L<lib dir> if you have libraries in a
 nonstandard directory <lib dir>
 LIBS        libraries to pass to the linker, e.g. -l<library>
 CPPFLAGS    (Objective) C/C++ preprocessor flags, e.g. -I<include dir> if
 you have headers in a nonstandard directory <include dir>
 CPP         C preprocessor
 PKG_CONFIG  path to pkg-config utility
 PKG_CONFIG_PATH
 directories to add to pkg-config's search path
 PKG_CONFIG_LIBDIR
 path overriding pkg-config's built-in search path
 LT_SYS_LIBRARY_PATH
 User-defined run-time library search path.
 CXX         C++ compiler command
 CXXFLAGS    C++ compiler flags
 CXXCPP      C++ preprocessor
 XMKMF       Path to xmkmf, Makefile generator for X Window System
 ZIP_CFLAGS  C compiler flags for ZIP, overriding pkg-config
 ZIP_LIBS    linker flags for ZIP, overriding pkg-config
 ZLIB_CFLAGS C compiler flags for ZLIB, overriding pkg-config
 ZLIB_LIBS   linker flags for ZLIB, overriding pkg-config
 LIBZSTD_CFLAGS
 C compiler flags for LIBZSTD, overriding pkg-config
 LIBZSTD_LIBS
 linker flags for LIBZSTD, overriding pkg-config
 AUTOTRACE_CFLAGS
 C compiler flags for AUTOTRACE, overriding pkg-config
 AUTOTRACE_LIBS
 linker flags for AUTOTRACE, overriding pkg-config
 fftw3_CFLAGS
 C compiler flags for fftw3, overriding pkg-config
 fftw3_LIBS  linker flags for fftw3, overriding pkg-config
 ddjvuapi_CFLAGS
 C compiler flags for ddjvuapi, overriding pkg-config
 ddjvuapi_LIBS
 linker flags for ddjvuapi, overriding pkg-config
 FONTCONFIG_CFLAGS
 C compiler flags for FONTCONFIG, overriding pkg-config
 FONTCONFIG_LIBS
 linker flags for FONTCONFIG, overriding pkg-config
 FREETYPE_CFLAGS
 C compiler flags for FREETYPE, overriding pkg-config
 FREETYPE_LIBS
 linker flags for FREETYPE, overriding pkg-config
 RAQM_CFLAGS C compiler flags for RAQM, overriding pkg-config
 RAQM_LIBS   linker flags for RAQM, overriding pkg-config
 GVC_CFLAGS  C compiler flags for GVC, overriding pkg-config
 GVC_LIBS    linker flags for GVC, overriding pkg-config
 HEIF_CFLAGS C compiler flags for HEIF, overriding pkg-config
 HEIF_LIBS   linker flags for HEIF, overriding pkg-config
 LCMS2_CFLAGS
 C compiler flags for LCMS2, overriding pkg-config
 LCMS2_LIBS  linker flags for LCMS2, overriding pkg-config
 LIBOPENJP2_CFLAGS
 C compiler flags for LIBOPENJP2, overriding pkg-config
 LIBOPENJP2_LIBS
 linker flags for LIBOPENJP2, overriding pkg-config
 LQR_CFLAGS  C compiler flags for LQR, overriding pkg-config
 LQR_LIBS    linker flags for LQR, overriding pkg-config
 LZMA_CFLAGS C compiler flags for LZMA, overriding pkg-config
 LZMA_LIBS   linker flags for LZMA, overriding pkg-config
 OPENEXR_CFLAGS
 C compiler flags for OPENEXR, overriding pkg-config
 OPENEXR_LIBS
 linker flags for OPENEXR, overriding pkg-config
 PANGO_CFLAGS
 C compiler flags for PANGO, overriding pkg-config
 PANGO_LIBS  linker flags for PANGO, overriding pkg-config
 PNG_CFLAGS  C compiler flags for PNG, overriding pkg-config
 PNG_LIBS    linker flags for PNG, overriding pkg-config
 RAW_R_CFLAGS
 C compiler flags for RAW_R, overriding pkg-config
 RAW_R_LIBS  linker flags for RAW_R, overriding pkg-config
 RSVG_CFLAGS C compiler flags for RSVG, overriding pkg-config
 RSVG_LIBS   linker flags for RSVG, overriding pkg-config
 CAIRO_SVG_CFLAGS
 C compiler flags for CAIRO_SVG, overriding pkg-config
 CAIRO_SVG_LIBS
 linker flags for CAIRO_SVG, overriding pkg-config
 WEBP_CFLAGS C compiler flags for WEBP, overriding pkg-config
 WEBP_LIBS   linker flags for WEBP, overriding pkg-config
 WEBPMUX_CFLAGS
 C compiler flags for WEBPMUX, overriding pkg-config
 WEBPMUX_LIBS
 linker flags for WEBPMUX, overriding pkg-config
 XML_CFLAGS  C compiler flags for XML, overriding pkg-config
 XML_LIBS    linker flags for XML, overriding pkg-config
 */
