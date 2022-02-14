import BuildSystem

public struct Nnedi3: Package {

  public init() {}

  public var defaultVersion: PackageVersion {
    "12"
  }

  public func recipe(for order: PackageOrder) throws -> PackageRecipe {
    let source: PackageSource
    switch order.version {
    case .head:
      source = .tarball(url: "https://github.com/dubhater/vapoursynth-nnedi3/archive/refs/heads/master.zip")
    case .stable(let version):
      source = .tarball(url: "https://github.com/dubhater/vapoursynth-nnedi3/archive/refs/tags/v\(version.toString(includeZeroMinor: false, includeZeroPatch: false)).tar.gz")
    }

    return .init(
      source: source,
      dependencies: [
        .buildTool(Autoconf.self),
        .buildTool(Automake.self),
        .buildTool(Libtool.self),
        .buildTool(PkgConfig.self),
        order.arch.isX86 ? .buildTool(Yasm.self) : nil,
        .runTime(Vapoursynth.self),
      ]
    )
  }

  public func build(with context: BuildContext) throws {
    try context.autogen()
    try context.configure()

    /*
     ref:
     https://github.com/mdtraj/mdtraj/pull/1684
     https://github.com/RustCrypto/utils/pull/393
     */

    let origin = """
#include <sys/auxv.h>

void getCPUFeatures(CPUFeatures *cpuFeatures) {
    memset(cpuFeatures, 0, sizeof(CPUFeatures));

    unsigned long long hwcap = getauxval(AT_HWCAP);

    cpuFeatures->can_run_vs = 1;

#if defined(NNEDI3_ARM)
    cpuFeatures->half_fp = !!(hwcap & HWCAP_ARM_HALF);
    cpuFeatures->edsp = !!(hwcap & HWCAP_ARM_EDSP);
    cpuFeatures->iwmmxt = !!(hwcap & HWCAP_ARM_IWMMXT);
    cpuFeatures->neon = !!(hwcap & HWCAP_ARM_NEON);
    cpuFeatures->fast_mult = !!(hwcap & HWCAP_ARM_FAST_MULT);
    cpuFeatures->idiv_a = !!(hwcap & HWCAP_ARM_IDIVA);
"""

    let fixed = """

    void getCPUFeatures(CPUFeatures *cpuFeatures) {
        memset(cpuFeatures, 0, sizeof(CPUFeatures));

    //    unsigned long long hwcap = getauxval(AT_HWCAP);

        cpuFeatures->can_run_vs = 1;

    #if defined(NNEDI3_ARM)
        cpuFeatures->half_fp = true;
        cpuFeatures->edsp = true;
        cpuFeatures->iwmmxt = true;
        cpuFeatures->neon = true;
        cpuFeatures->fast_mult = true;
        cpuFeatures->idiv_a = true;
    """

    try replace(contentIn: "src/cpufeatures.cpp", matching: origin, with: fixed)

    try context.make()
    try context.make("install")

    try context.moveItem(at: context.prefix.appending("share/nnedi3/nnedi3_weights.bin"), to: context.prefix.appending("lib/nnedi3_weights.bin"))
    try Vapoursynth.install(plugin: context.prefix.appending("lib/libnnedi3"), context: context)
  }
}
