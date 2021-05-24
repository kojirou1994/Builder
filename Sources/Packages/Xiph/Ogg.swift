import BuildSystem

public struct Ogg: Package {

  public init() {}
  /*
   1.3.4 always fail?
   https://gitlab.xiph.org/xiph/ogg/-/issues/2298
   */
  public var defaultVersion: PackageVersion {
    "1.3.4"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    var source: PackageSource
    switch order.version {
    case .head:
      source = .repository(url: "https://github.com/xiph/ogg.git")
    case .stable(let version):
      source = .tarball(url: "https://downloads.xiph.org/releases/ogg/libogg-\(version.toString()).tar.gz")
    }

    switch order.version {
    case "1.3.3":
      source.patches.append(.raw(v133HeaderPatch))
    case "1.3.4":
      source.patches.append(.raw(v134HeaderPatch))
    default:
      break
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
      ],
      products: [
        .library(name: "libogg", headers: ["ogg/ogg.h", "ogg/os_types.h"]),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autoreconf()

    try context.fixAutotoolsForDarwin()

    try context.configure(
      configureEnableFlag(false, CommonOptions.dependencyTracking),
      context.libraryType.staticConfigureFlag,
      context.libraryType.sharedConfigureFlag
    )

    try context.make()
    if context.canRunTests {
      try context.make("check")
    }
    try context.make(parallelJobs: 1, "install")

    try replace(contentIn: context.prefix.appending("include/ogg/ogg.h"), matching: "#include <ogg/os_types.h>", with: "#include \"os_types.h\"")
  }

}

private let v133HeaderPatch = """
From d637c02595ab00b5c849ef1c0771464b653fb71b Mon Sep 17 00:00:00 2001
From: kojirou <kojirouhtc@gmail.com>
Date: Mon, 24 May 2021 06:16:05 +0800
Subject: [PATCH] fix macOS header

---
include/ogg/os_types.h | 2 +-
1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/ogg/os_types.h b/include/ogg/os_types.h
index b8f5630..66839e5 100644
--- a/include/ogg/os_types.h
+++ b/include/ogg/os_types.h
@@ -69,7 +69,7 @@

#elif (defined(__APPLE__) && defined(__MACH__)) /* MacOS X Framework build */

-#  include <inttypes.h>
+#  include <stdint.h>
  typedef int16_t ogg_int16_t;
  typedef uint16_t ogg_uint16_t;
  typedef int32_t ogg_int32_t;
--
2.30.1 (Apple Git-130)

"""

private let v134HeaderPatch = """
From 140c385678f95d8c5c766f9c2563c6f296b2e15f Mon Sep 17 00:00:00 2001
From: kojirou <kojirouhtc@gmail.com>
Date: Mon, 24 May 2021 06:24:46 +0800
Subject: [PATCH] fix macOS header

---
 include/ogg/os_types.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/ogg/os_types.h b/include/ogg/os_types.h
index eb8a322..6aeecae 100644
--- a/include/ogg/os_types.h
+++ b/include/ogg/os_types.h
@@ -70,7 +70,7 @@

 #elif (defined(__APPLE__) && defined(__MACH__)) /* MacOS X Framework build */

-#  include <sys/types.h>
+#  include <stdint.h>
    typedef int16_t ogg_int16_t;
    typedef uint16_t ogg_uint16_t;
    typedef int32_t ogg_int32_t;
--
2.30.1 (Apple Git-130)


"""
