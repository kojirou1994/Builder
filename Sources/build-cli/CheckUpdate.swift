import BuildSystem
import Packages

struct CheckUpdate: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [
      PackageCheckUpdateCommand<AddGrain>.self,
      PackageCheckUpdateCommand<Aom>.self,
      PackageCheckUpdateCommand<Aribb24>.self,
      PackageCheckUpdateCommand<Ass>.self,
      PackageCheckUpdateCommand<Autoconf>.self,
      PackageCheckUpdateCommand<Automake>.self,
      PackageCheckUpdateCommand<Bilateral>.self,
      PackageCheckUpdateCommand<Bm3d>.self,
      PackageCheckUpdateCommand<Boost>.self,
      PackageCheckUpdateCommand<BoringSSL>.self,
      PackageCheckUpdateCommand<Brotli>.self,
      PackageCheckUpdateCommand<Bwdif>.self,
      PackageCheckUpdateCommand<Bzip2>.self,
      PackageCheckUpdateCommand<CAres>.self,
      PackageCheckUpdateCommand<Cas>.self,
      PackageCheckUpdateCommand<Cmake>.self,
      PackageCheckUpdateCommand<Corkscrew>.self,
      PackageCheckUpdateCommand<Ctmf>.self,
      PackageCheckUpdateCommand<Curve>.self,
      PackageCheckUpdateCommand<DCTFilter>.self,
      PackageCheckUpdateCommand<DeLogo>.self,
      PackageCheckUpdateCommand<Deblock>.self,
      PackageCheckUpdateCommand<DeblockPP7>.self,
      PackageCheckUpdateCommand<Dfttest>.self,
      PackageCheckUpdateCommand<DocbookXsl>.self,
      PackageCheckUpdateCommand<Dupd>.self,
      PackageCheckUpdateCommand<Dvdcss>.self,
      PackageCheckUpdateCommand<Dvdread>.self,
      PackageCheckUpdateCommand<Ebml>.self,
      PackageCheckUpdateCommand<Eedi2>.self,
      PackageCheckUpdateCommand<Eedi3>.self,
      PackageCheckUpdateCommand<FFT3DFilter>.self,
      PackageCheckUpdateCommand<FdkAac>.self,
      PackageCheckUpdateCommand<Ffmpeg>.self,
      PackageCheckUpdateCommand<Ffms2>.self,
      PackageCheckUpdateCommand<File>.self,
      PackageCheckUpdateCommand<Fish>.self,
      PackageCheckUpdateCommand<Flac>.self,
      PackageCheckUpdateCommand<Flash3kyuuDeband>.self,
      PackageCheckUpdateCommand<Fmt>.self,
      PackageCheckUpdateCommand<Fmtconv>.self,
      PackageCheckUpdateCommand<Freetype>.self,
      PackageCheckUpdateCommand<Fribidi>.self,
      PackageCheckUpdateCommand<Gcrypt>.self,
      PackageCheckUpdateCommand<Gettext>.self,
      PackageCheckUpdateCommand<Giflib>.self,
      PackageCheckUpdateCommand<GnuTar>.self,
      PackageCheckUpdateCommand<Go>.self,
      PackageCheckUpdateCommand<GpgError>.self,
      PackageCheckUpdateCommand<Harfbuzz>.self,
      PackageCheckUpdateCommand<IT>.self,
      PackageCheckUpdateCommand<Icu4c>.self,
      PackageCheckUpdateCommand<Ilmbase>.self,
      PackageCheckUpdateCommand<ImageMagick>.self,
      PackageCheckUpdateCommand<Imath>.self,
      PackageCheckUpdateCommand<Jpcre2>.self,
      PackageCheckUpdateCommand<JpegXL>.self,
      PackageCheckUpdateCommand<KNLMeansCL>.self,
      PackageCheckUpdateCommand<LGhost>.self,
      PackageCheckUpdateCommand<Lame>.self,
      PackageCheckUpdateCommand<Libtool>.self,
      PackageCheckUpdateCommand<Lsmash>.self,
      PackageCheckUpdateCommand<LsmashWorks>.self,
      PackageCheckUpdateCommand<M4>.self,
      PackageCheckUpdateCommand<Matroska>.self,
      PackageCheckUpdateCommand<Mbedtls>.self,
      PackageCheckUpdateCommand<Mediainfo>.self,
      PackageCheckUpdateCommand<Mkvtoolnix>.self,
      PackageCheckUpdateCommand<Mozjpeg>.self,
      PackageCheckUpdateCommand<Mvtools>.self,
      PackageCheckUpdateCommand<Nasm>.self,
      PackageCheckUpdateCommand<NeoFFT3D>.self,
      PackageCheckUpdateCommand<NeoGradientMask>.self,
      PackageCheckUpdateCommand<NeoMiniDeen>.self,
      PackageCheckUpdateCommand<Ninja>.self,
      PackageCheckUpdateCommand<NlohmannJson>.self,
      PackageCheckUpdateCommand<Nnedi3>.self,
      PackageCheckUpdateCommand<Nnedi3cl>.self,
      PackageCheckUpdateCommand<Numactl>.self,
      PackageCheckUpdateCommand<Ogg>.self,
      PackageCheckUpdateCommand<Opencore>.self,
      PackageCheckUpdateCommand<Openexr>.self,
      PackageCheckUpdateCommand<Openssl>.self,
      PackageCheckUpdateCommand<Opus>.self,
      PackageCheckUpdateCommand<OpusTools>.self,
      PackageCheckUpdateCommand<Opusenc>.self,
      PackageCheckUpdateCommand<Opusfile>.self,
      PackageCheckUpdateCommand<P7Zip>.self,
      PackageCheckUpdateCommand<Pcre2>.self,
      PackageCheckUpdateCommand<PkgConfig>.self,
      PackageCheckUpdateCommand<Png>.self,
      PackageCheckUpdateCommand<Pugixml>.self,
      PackageCheckUpdateCommand<Rav1e>.self,
      PackageCheckUpdateCommand<ReadMpls>.self,
      PackageCheckUpdateCommand<Retinex>.self,
      PackageCheckUpdateCommand<Rmff>.self,
      PackageCheckUpdateCommand<SangNomMod>.self,
      PackageCheckUpdateCommand<Sdl2>.self,
      PackageCheckUpdateCommand<SvtAv1>.self,
      PackageCheckUpdateCommand<TCanny>.self,
      PackageCheckUpdateCommand<TDeintMod>.self,
      PackageCheckUpdateCommand<TTempSmooth>.self,
      PackageCheckUpdateCommand<Utfcpp>.self,
      PackageCheckUpdateCommand<VagueDenoiser>.self,
      PackageCheckUpdateCommand<Vmaf>.self,
      PackageCheckUpdateCommand<Vorbis>.self,
      PackageCheckUpdateCommand<Vpx>.self,
      PackageCheckUpdateCommand<Waifu2xCaffe>.self,
      PackageCheckUpdateCommand<Webp>.self,
      PackageCheckUpdateCommand<Xml2>.self,
      PackageCheckUpdateCommand<Xslt>.self,
      PackageCheckUpdateCommand<Xz>.self,
      PackageCheckUpdateCommand<Yadifmod>.self,
      PackageCheckUpdateCommand<Yasm>.self,
      PackageCheckUpdateCommand<Zlib>.self,
      PackageCheckUpdateCommand<Zstd>.self,
      PackageCheckUpdateCommand<Zvbi>.self,
      PackageCheckUpdateCommand<x264>.self,
      PackageCheckUpdateCommand<x265>.self,
    ])
  } // end of configuration
} // end of CheckUpdate