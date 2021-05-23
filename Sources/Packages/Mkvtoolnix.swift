import BuildSystem

public struct Mkvtoolnix: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "57"
  }

  /*
   macOS app:
   https://mkvtoolnix.download/macos/MKVToolNix-56.1.0.dmg

   */
  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    var source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://gitlab.com/mbunkus/mkvtoolnix.git")
    case .stable(let version):
      let versionString = version.toString()
      source = .tarball(url: "https://mkvtoolnix.download/sources/mkvtoolnix-\(versionString).tar.xz")
    }

    source.patches.append(.raw(noCachePatch))
    source.patches.append(.raw(headerFix))

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        .runTime(Vorbis.self),
        .runTime(Ebml.self),
        .runTime(Matroska.self),
        .runTime(Pugixml.self),
        .runTime(Pcre2.self),
        .runTime(Fmt.self),
        .runTime(Flac.self),
        .runTime(Jpcre2.self),
        .runTime(Boost.self),
        .runTime(NlohmannJson.self),
        .runTime(Zlib.self),
        .runTime(Dvdread.self),
//        .brew(["docbook-xsl"], requireLinked: false),
      ],
      supportedLibraryType: nil
    )
  }
  
  public func build(with context: BuildContext) throws {

    try context.autogen()

    try context.configure(
      configureEnableFlag(false, "qt"),
      "--with-docbook-xsl-root=/opt/local/share/xsl/docbook-xsl-nons"
    )

    try context.launch("rake", context.parallelJobs.map { "-j\($0)" } )
    try context.launch("rake", "install")
  }

}


private let noCachePatch = """
From d7b909dcffd8c13c8f8e1b35ddf541fa67cd880a Mon Sep 17 00:00:00 2001
From: kojirou <kojirouhtc@gmail.com>
Date: Mon, 24 May 2021 00:22:14 +0800
Subject: [PATCH] disable file cache

---
 src/common/mm_file_io/unix.cpp | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/src/common/mm_file_io/unix.cpp b/src/common/mm_file_io/unix.cpp
index 458669fb7..6fc09b6ff 100644
--- a/src/common/mm_file_io/unix.cpp
+++ b/src/common/mm_file_io/unix.cpp
@@ -78,6 +78,8 @@ mm_file_io_private_c::mm_file_io_private_c(std::string const &p_file_name,

   if (!file)
     throw mtx::mm_io::open_x{mtx::mm_io::make_error_code()};
+
+  fcntl(fileno(file), F_NOCACHE, 1);
 }

 void
--
2.30.1 (Apple Git-130)


"""

private let headerFix = """
From 610c3c48da6ac83f307e31f0c68c870ed492beb6 Mon Sep 17 00:00:00 2001
From: kojirou <kojirouhtc@gmail.com>
Date: Mon, 24 May 2021 01:59:23 +0800
Subject: [PATCH] add fcntl header

---
 src/common/mm_file_io/unix.cpp | 1 +
 1 file changed, 1 insertion(+)

diff --git a/src/common/mm_file_io/unix.cpp b/src/common/mm_file_io/unix.cpp
index 6fc09b6ff..06c8a2a42 100644
--- a/src/common/mm_file_io/unix.cpp
+++ b/src/common/mm_file_io/unix.cpp
@@ -27,6 +27,7 @@
 #if defined(SYS_APPLE)
 # include "common/fs_sys_helpers.h"
 #endif
+#include <fcntl.h>

 mm_file_io_private_c::mm_file_io_private_c(std::string const &p_file_name,
                                            open_mode const p_mode)
--
2.30.1 (Apple Git-130)


"""
