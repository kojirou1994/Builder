import BuildSystem
import Packages

struct Build: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [
      PackageBuildCommand<AddGrain>.self,
      PackageBuildCommand<Aom>.self,
      PackageBuildCommand<Aribb24>.self,
      PackageBuildCommand<Ass>.self,
      PackageBuildCommand<Autoconf>.self,
      PackageBuildCommand<Automake>.self,
      PackageBuildCommand<Bilateral>.self,
      PackageBuildCommand<Bluray>.self,
      PackageBuildCommand<Bm3d>.self,
      PackageBuildCommand<Boost>.self,
      PackageBuildCommand<BoringSSL>.self,
      PackageBuildCommand<Brotli>.self,
      PackageBuildCommand<Bwdif>.self,
      PackageBuildCommand<Bzip2>.self,
      PackageBuildCommand<CAres>.self,
      PackageBuildCommand<Cas>.self,
      PackageBuildCommand<Choco>.self,
      PackageBuildCommand<Cmake>.self,
      PackageBuildCommand<Corkscrew>.self,
      PackageBuildCommand<Ctmf>.self,
      PackageBuildCommand<Curve>.self,
      PackageBuildCommand<DCTFilter>.self,
      PackageBuildCommand<Deblock>.self,
      PackageBuildCommand<DeblockPP7>.self,
      PackageBuildCommand<Delogo>.self,
      PackageBuildCommand<Dfttest>.self,
      PackageBuildCommand<DocbookXsl>.self,
      PackageBuildCommand<Dupd>.self,
      PackageBuildCommand<Dvdcss>.self,
      PackageBuildCommand<Dvdread>.self,
      PackageBuildCommand<Ebml>.self,
      PackageBuildCommand<Eedi2>.self,
      PackageBuildCommand<Eedi3>.self,
      PackageBuildCommand<FFT3DFilter>.self,
      PackageBuildCommand<FdkAac>.self,
      PackageBuildCommand<Ffmpeg>.self,
      PackageBuildCommand<Ffms2>.self,
      PackageBuildCommand<File>.self,
      PackageBuildCommand<Fish>.self,
      PackageBuildCommand<Flac>.self,
      PackageBuildCommand<Flash3kyuuDeband>.self,
      PackageBuildCommand<Fmt>.self,
      PackageBuildCommand<Fmtconv>.self,
      PackageBuildCommand<Freetype>.self,
      PackageBuildCommand<Fribidi>.self,
      PackageBuildCommand<Gcc>.self,
      PackageBuildCommand<Gcrypt>.self,
      PackageBuildCommand<Gettext>.self,
      PackageBuildCommand<Giflib>.self,
      PackageBuildCommand<Gmp>.self,
      PackageBuildCommand<GnuTar>.self,
      PackageBuildCommand<Go>.self,
      PackageBuildCommand<GpgError>.self,
      PackageBuildCommand<Handbrake>.self,
      PackageBuildCommand<Harfbuzz>.self,
      PackageBuildCommand<Hwloc>.self,
      PackageBuildCommand<IT>.self,
      PackageBuildCommand<Icu4c>.self,
      PackageBuildCommand<Ilmbase>.self,
      PackageBuildCommand<ImageMagick>.self,
      PackageBuildCommand<Imath>.self,
      PackageBuildCommand<Iperf2>.self,
      PackageBuildCommand<Iperf3>.self,
      PackageBuildCommand<Isl>.self,
      PackageBuildCommand<Jpcre2>.self,
      PackageBuildCommand<JpegXL>.self,
      PackageBuildCommand<KNLMeansCL>.self,
      PackageBuildCommand<LGhost>.self,
      PackageBuildCommand<Lame>.self,
      PackageBuildCommand<Libarchive>.self,
      PackageBuildCommand<Libb2>.self,
      PackageBuildCommand<Libevent>.self,
      PackageBuildCommand<Libtool>.self,
      PackageBuildCommand<Lsmash>.self,
      PackageBuildCommand<LsmashWorks>.self,
      PackageBuildCommand<Lz4>.self,
      PackageBuildCommand<Lzfse>.self,
      PackageBuildCommand<Lzo>.self,
      PackageBuildCommand<M4>.self,
      PackageBuildCommand<Matroska>.self,
      PackageBuildCommand<Mbedtls>.self,
      PackageBuildCommand<Mediainfo>.self,
      PackageBuildCommand<Mkvtoolnix>.self,
      PackageBuildCommand<Mozjpeg>.self,
      PackageBuildCommand<Mpc>.self,
      PackageBuildCommand<Mpfr>.self,
      PackageBuildCommand<Mvtools>.self,
      PackageBuildCommand<Nasm>.self,
      PackageBuildCommand<NeoFFT3D>.self,
      PackageBuildCommand<NeoGradientMask>.self,
      PackageBuildCommand<NeoMiniDeen>.self,
      PackageBuildCommand<Ninja>.self,
      PackageBuildCommand<NlohmannJson>.self,
      PackageBuildCommand<Nnedi3>.self,
      PackageBuildCommand<Nnedi3cl>.self,
      PackageBuildCommand<Numactl>.self,
      PackageBuildCommand<Ogg>.self,
      PackageBuildCommand<Opencore>.self,
      PackageBuildCommand<Openexr>.self,
      PackageBuildCommand<Openssl>.self,
      PackageBuildCommand<Opus>.self,
      PackageBuildCommand<OpusTools>.self,
      PackageBuildCommand<Opusenc>.self,
      PackageBuildCommand<Opusfile>.self,
      PackageBuildCommand<P7Zip>.self,
      PackageBuildCommand<Pcre2>.self,
      PackageBuildCommand<PkgConfig>.self,
      PackageBuildCommand<Png>.self,
      PackageBuildCommand<Pugixml>.self,
      PackageBuildCommand<Rav1e>.self,
      PackageBuildCommand<ReadMpls>.self,
      PackageBuildCommand<Retinex>.self,
      PackageBuildCommand<Rmff>.self,
      PackageBuildCommand<SangNomMod>.self,
      PackageBuildCommand<Sdl2>.self,
      PackageBuildCommand<SvtAv1>.self,
      PackageBuildCommand<TCanny>.self,
      PackageBuildCommand<TDeintMod>.self,
      PackageBuildCommand<TTempSmooth>.self,
      PackageBuildCommand<Utfcpp>.self,
      PackageBuildCommand<VagueDenoiser>.self,
      PackageBuildCommand<Vapoursynth>.self,
      PackageBuildCommand<Vmaf>.self,
      PackageBuildCommand<Vorbis>.self,
      PackageBuildCommand<Vpx>.self,
      PackageBuildCommand<Waifu2xCaffe>.self,
      PackageBuildCommand<Webp>.self,
      PackageBuildCommand<Xml2>.self,
      PackageBuildCommand<Xslt>.self,
      PackageBuildCommand<Xz>.self,
      PackageBuildCommand<Yadifmod>.self,
      PackageBuildCommand<Yasm>.self,
      PackageBuildCommand<Zimg>.self,
      PackageBuildCommand<Zlib>.self,
      PackageBuildCommand<Zstd>.self,
      PackageBuildCommand<Zvbi>.self,
      PackageBuildCommand<x264>.self,
      PackageBuildCommand<x265>.self,
    ])
  } // end of configuration
} // end of Build