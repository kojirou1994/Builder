import BuildSystem
import Packages

struct BuildAll: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [
      PackageBuildAllCommand<AddGrain>.self,
      PackageBuildAllCommand<Adjust>.self,
      PackageBuildAllCommand<Aom>.self,
      PackageBuildAllCommand<Aribb24>.self,
      PackageBuildAllCommand<Asharp>.self,
      PackageBuildAllCommand<Ass>.self,
      PackageBuildAllCommand<Assrender>.self,
      PackageBuildAllCommand<Autoconf>.self,
      PackageBuildAllCommand<Automake>.self,
      PackageBuildAllCommand<Bestaudiosource>.self,
      PackageBuildAllCommand<Bilateral>.self,
      PackageBuildAllCommand<Bluray>.self,
      PackageBuildAllCommand<Bm3d>.self,
      PackageBuildAllCommand<Boost>.self,
      PackageBuildAllCommand<BoringSSL>.self,
      PackageBuildAllCommand<Brotli>.self,
      PackageBuildAllCommand<Bwdif>.self,
      PackageBuildAllCommand<Bzip2>.self,
      PackageBuildAllCommand<CAres>.self,
      PackageBuildAllCommand<CargoUpdate>.self,
      PackageBuildAllCommand<Cas>.self,
      PackageBuildAllCommand<Choco>.self,
      PackageBuildAllCommand<Cmake>.self,
      PackageBuildAllCommand<Corkscrew>.self,
      PackageBuildAllCommand<Ctmf>.self,
      PackageBuildAllCommand<Curl>.self,
      PackageBuildAllCommand<Curve>.self,
      PackageBuildAllCommand<DCTFilter>.self,
      PackageBuildAllCommand<Dav1d>.self,
      PackageBuildAllCommand<DeLogo>.self,
      PackageBuildAllCommand<Deblock>.self,
      PackageBuildAllCommand<DeblockPP7>.self,
      PackageBuildAllCommand<Dfttest>.self,
      PackageBuildAllCommand<DlbMp4base>.self,
      PackageBuildAllCommand<DocbookXsl>.self,
      PackageBuildAllCommand<Dupd>.self,
      PackageBuildAllCommand<Dvdcss>.self,
      PackageBuildAllCommand<Dvdread>.self,
      PackageBuildAllCommand<Ebml>.self,
      PackageBuildAllCommand<Eedi2>.self,
      PackageBuildAllCommand<Eedi3>.self,
      PackageBuildAllCommand<FFT3DFilter>.self,
      PackageBuildAllCommand<FdkAac>.self,
      PackageBuildAllCommand<Ffmpeg>.self,
      PackageBuildAllCommand<Ffms2>.self,
      PackageBuildAllCommand<Fftw>.self,
      PackageBuildAllCommand<File>.self,
      PackageBuildAllCommand<Fish>.self,
      PackageBuildAllCommand<Flac>.self,
      PackageBuildAllCommand<Flash3kyuuDeband>.self,
      PackageBuildAllCommand<Fluxsmooth>.self,
      PackageBuildAllCommand<Fmt>.self,
      PackageBuildAllCommand<Fmtconv>.self,
      PackageBuildAllCommand<Freetype>.self,
      PackageBuildAllCommand<Fribidi>.self,
      PackageBuildAllCommand<GasPreprocessor>.self,
      PackageBuildAllCommand<Gcc>.self,
      PackageBuildAllCommand<Gcrypt>.self,
      PackageBuildAllCommand<Gettext>.self,
      PackageBuildAllCommand<Gflags>.self,
      PackageBuildAllCommand<Giflib>.self,
      PackageBuildAllCommand<Gmp>.self,
      PackageBuildAllCommand<GnuTar>.self,
      PackageBuildAllCommand<Go>.self,
      PackageBuildAllCommand<Googletest>.self,
      PackageBuildAllCommand<Gpac>.self,
      PackageBuildAllCommand<GpgError>.self,
      PackageBuildAllCommand<Handbrake>.self,
      PackageBuildAllCommand<Harfbuzz>.self,
      PackageBuildAllCommand<Havsfunc>.self,
      PackageBuildAllCommand<Highway>.self,
      PackageBuildAllCommand<Hqdn3d>.self,
      PackageBuildAllCommand<Hwloc>.self,
      PackageBuildAllCommand<IT>.self,
      PackageBuildAllCommand<Icu4c>.self,
      PackageBuildAllCommand<Ilmbase>.self,
      PackageBuildAllCommand<ImageMagick>.self,
      PackageBuildAllCommand<Imath>.self,
      PackageBuildAllCommand<Imwri>.self,
      PackageBuildAllCommand<Iperf2>.self,
      PackageBuildAllCommand<Iperf3>.self,
      PackageBuildAllCommand<Isl>.self,
      PackageBuildAllCommand<Jemalloc>.self,
      PackageBuildAllCommand<Jpcre2>.self,
      PackageBuildAllCommand<JpegXL>.self,
      PackageBuildAllCommand<KNLMeansCL>.self,
      PackageBuildAllCommand<Kvazaar>.self,
      PackageBuildAllCommand<LGhost>.self,
      PackageBuildAllCommand<Lame>.self,
      PackageBuildAllCommand<Libarchive>.self,
      PackageBuildAllCommand<Libb2>.self,
      PackageBuildAllCommand<Libde265>.self,
      PackageBuildAllCommand<Libev>.self,
      PackageBuildAllCommand<Libevent>.self,
      PackageBuildAllCommand<Libgit2>.self,
      PackageBuildAllCommand<Libheif>.self,
      PackageBuildAllCommand<Libltdl>.self,
      PackageBuildAllCommand<Libssh>.self,
      PackageBuildAllCommand<Libssh2>.self,
      PackageBuildAllCommand<Libtool>.self,
      PackageBuildAllCommand<Libuv>.self,
      PackageBuildAllCommand<Lsmash>.self,
      PackageBuildAllCommand<LsmashWorks>.self,
      PackageBuildAllCommand<Lz4>.self,
      PackageBuildAllCommand<Lzfse>.self,
      PackageBuildAllCommand<Lzo>.self,
      PackageBuildAllCommand<M4>.self,
      PackageBuildAllCommand<Matroska>.self,
      PackageBuildAllCommand<Mbedtls>.self,
      PackageBuildAllCommand<MediaBundle>.self,
      PackageBuildAllCommand<MediaInfo>.self,
      PackageBuildAllCommand<MediaInfoLib>.self,
      PackageBuildAllCommand<Meson>.self,
      PackageBuildAllCommand<MiscFilters>.self,
      PackageBuildAllCommand<Mkvtoolnix>.self,
      PackageBuildAllCommand<Mozjpeg>.self,
      PackageBuildAllCommand<Mpc>.self,
      PackageBuildAllCommand<Mpfr>.self,
      PackageBuildAllCommand<Mpv>.self,
      PackageBuildAllCommand<Mvsfunc>.self,
      PackageBuildAllCommand<Mvtools>.self,
      PackageBuildAllCommand<Nasm>.self,
      PackageBuildAllCommand<NeoFFT3D>.self,
      PackageBuildAllCommand<NeoGradientMask>.self,
      PackageBuildAllCommand<NeoMiniDeen>.self,
      PackageBuildAllCommand<Nghttp2>.self,
      PackageBuildAllCommand<Ninja>.self,
      PackageBuildAllCommand<NlohmannJson>.self,
      PackageBuildAllCommand<Nnedi3>.self,
      PackageBuildAllCommand<Nnedi3cl>.self,
      PackageBuildAllCommand<Node>.self,
      PackageBuildAllCommand<Numactl>.self,
      PackageBuildAllCommand<Ogg>.self,
      PackageBuildAllCommand<Opencore>.self,
      PackageBuildAllCommand<Openexr>.self,
      PackageBuildAllCommand<Openssl>.self,
      PackageBuildAllCommand<Opus>.self,
      PackageBuildAllCommand<OpusTools>.self,
      PackageBuildAllCommand<Opusenc>.self,
      PackageBuildAllCommand<Opusfile>.self,
      PackageBuildAllCommand<P7Zip>.self,
      PackageBuildAllCommand<Pcre2>.self,
      PackageBuildAllCommand<PkgConfig>.self,
      PackageBuildAllCommand<Png>.self,
      PackageBuildAllCommand<Pugixml>.self,
      PackageBuildAllCommand<Python>.self,
      PackageBuildAllCommand<Rav1e>.self,
      PackageBuildAllCommand<ReadMpls>.self,
      PackageBuildAllCommand<Retinex>.self,
      PackageBuildAllCommand<Rmff>.self,
      PackageBuildAllCommand<SangNomMod>.self,
      PackageBuildAllCommand<Sangnom>.self,
      PackageBuildAllCommand<Sdl2>.self,
      PackageBuildAllCommand<Smartmontools>.self,
      PackageBuildAllCommand<SvtAv1>.self,
      PackageBuildAllCommand<TCanny>.self,
      PackageBuildAllCommand<TDeintMod>.self,
      PackageBuildAllCommand<TTempSmooth>.self,
      PackageBuildAllCommand<Temporalsoften2>.self,
      PackageBuildAllCommand<Tiff>.self,
      PackageBuildAllCommand<Utfcpp>.self,
      PackageBuildAllCommand<VagueDenoiser>.self,
      PackageBuildAllCommand<Vapoursynth>.self,
      PackageBuildAllCommand<VapoursynthBundle>.self,
      PackageBuildAllCommand<Vivtc>.self,
      PackageBuildAllCommand<Vmaf>.self,
      PackageBuildAllCommand<Vorbis>.self,
      PackageBuildAllCommand<Vpx>.self,
      PackageBuildAllCommand<Waifu2xCaffe>.self,
      PackageBuildAllCommand<Webp>.self,
      PackageBuildAllCommand<Xml2>.self,
      PackageBuildAllCommand<Xslt>.self,
      PackageBuildAllCommand<Xvid>.self,
      PackageBuildAllCommand<Xz>.self,
      PackageBuildAllCommand<Yadifmod>.self,
      PackageBuildAllCommand<Yasm>.self,
      PackageBuildAllCommand<ZenLib>.self,
      PackageBuildAllCommand<Zimg>.self,
      PackageBuildAllCommand<Zlib>.self,
      PackageBuildAllCommand<Znedi3>.self,
      PackageBuildAllCommand<Zstd>.self,
      PackageBuildAllCommand<Zvbi>.self,
      PackageBuildAllCommand<x264>.self,
      PackageBuildAllCommand<x265>.self,
      PackageBuildAllCommand<yyjson>.self,
    ])
  } // end of configuration
} // end of BuildAll