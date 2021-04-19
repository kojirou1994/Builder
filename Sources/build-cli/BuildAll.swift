import BuildSystem
import Packages

struct BuildAll: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [
      PackageBuildAllCommand<AddGrain>.self,
      PackageBuildAllCommand<Aom>.self,
      PackageBuildAllCommand<Aribb24>.self,
      PackageBuildAllCommand<Ass>.self,
      PackageBuildAllCommand<Bilateral>.self,
      PackageBuildAllCommand<Bm3d>.self,
      PackageBuildAllCommand<BoringSSL>.self,
      PackageBuildAllCommand<Brotli>.self,
      PackageBuildAllCommand<Bwdif>.self,
      PackageBuildAllCommand<CAres>.self,
      PackageBuildAllCommand<Cas>.self,
      PackageBuildAllCommand<Cmake>.self,
      PackageBuildAllCommand<Ctmf>.self,
      PackageBuildAllCommand<Curve>.self,
      PackageBuildAllCommand<DCTFilter>.self,
      PackageBuildAllCommand<DeLogo>.self,
      PackageBuildAllCommand<Deblock>.self,
      PackageBuildAllCommand<DeblockPP7>.self,
      PackageBuildAllCommand<Dfttest>.self,
      PackageBuildAllCommand<Dupd>.self,
      PackageBuildAllCommand<Ebml>.self,
      PackageBuildAllCommand<Eedi2>.self,
      PackageBuildAllCommand<Eedi3>.self,
      PackageBuildAllCommand<FFT3DFilter>.self,
      PackageBuildAllCommand<FdkAac>.self,
      PackageBuildAllCommand<Ffmpeg>.self,
      PackageBuildAllCommand<Ffms2>.self,
      PackageBuildAllCommand<Flac>.self,
      PackageBuildAllCommand<Flash3kyuuDeband>.self,
      PackageBuildAllCommand<Fmt>.self,
      PackageBuildAllCommand<Fmtconv>.self,
      PackageBuildAllCommand<Freetype>.self,
      PackageBuildAllCommand<Fribidi>.self,
      PackageBuildAllCommand<Gcrypt>.self,
      PackageBuildAllCommand<Giflib>.self,
      PackageBuildAllCommand<GnuTar>.self,
      PackageBuildAllCommand<GpgError>.self,
      PackageBuildAllCommand<Harfbuzz>.self,
      PackageBuildAllCommand<IT>.self,
      PackageBuildAllCommand<Icu4c>.self,
      PackageBuildAllCommand<Ilmbase>.self,
      PackageBuildAllCommand<ImageMagick>.self,
      PackageBuildAllCommand<Imath>.self,
      PackageBuildAllCommand<Jpcre2>.self,
      PackageBuildAllCommand<JpegXL>.self,
      PackageBuildAllCommand<KNLMeansCL>.self,
      PackageBuildAllCommand<LGhost>.self,
      PackageBuildAllCommand<Lame>.self,
      PackageBuildAllCommand<Lsmash>.self,
      PackageBuildAllCommand<LsmashWorks>.self,
      PackageBuildAllCommand<Matroska>.self,
      PackageBuildAllCommand<Mbedtls>.self,
      PackageBuildAllCommand<Mediainfo>.self,
      PackageBuildAllCommand<Mkvtoolnix>.self,
      PackageBuildAllCommand<Mozjpeg>.self,
      PackageBuildAllCommand<Mvtools>.self,
      PackageBuildAllCommand<Nasm>.self,
      PackageBuildAllCommand<NeoFFT3D>.self,
      PackageBuildAllCommand<NeoGradientMask>.self,
      PackageBuildAllCommand<NeoMiniDeen>.self,
      PackageBuildAllCommand<Ninja>.self,
      PackageBuildAllCommand<Nnedi3>.self,
      PackageBuildAllCommand<Nnedi3cl>.self,
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
      PackageBuildAllCommand<Png>.self,
      PackageBuildAllCommand<Pugixml>.self,
      PackageBuildAllCommand<Rav1e>.self,
      PackageBuildAllCommand<ReadMpls>.self,
      PackageBuildAllCommand<Retinex>.self,
      PackageBuildAllCommand<SangNomMod>.self,
      PackageBuildAllCommand<Sdl2>.self,
      PackageBuildAllCommand<SvtAv1>.self,
      PackageBuildAllCommand<TCanny>.self,
      PackageBuildAllCommand<TDeintMod>.self,
      PackageBuildAllCommand<TTempSmooth>.self,
      PackageBuildAllCommand<VagueDenoiser>.self,
      PackageBuildAllCommand<Vmaf>.self,
      PackageBuildAllCommand<Vorbis>.self,
      PackageBuildAllCommand<Vpx>.self,
      PackageBuildAllCommand<Waifu2xCaffe>.self,
      PackageBuildAllCommand<Webp>.self,
      PackageBuildAllCommand<Xml2>.self,
      PackageBuildAllCommand<Xslt>.self,
      PackageBuildAllCommand<Xz>.self,
      PackageBuildAllCommand<Yadifmod>.self,
      PackageBuildAllCommand<Yasm>.self,
      PackageBuildAllCommand<Zstd>.self,
      PackageBuildAllCommand<Zvbi>.self,
      PackageBuildAllCommand<x264>.self,
      PackageBuildAllCommand<x265>.self,
    ])
  } // end of configuration
} // end of BuildAll