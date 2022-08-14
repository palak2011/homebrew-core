class Synfig < Formula
  desc "Command-line renderer"
  homepage "https://synfig.org/"
  license "GPL-3.0-or-later"
  revision 2

  stable do
    url "https://downloads.sourceforge.net/project/synfig/releases/1.4.2/synfig-1.4.2.tar.gz"
    mirror "https://github.com/synfig/synfig/releases/download/v1.4.2/synfig-1.4.2.tar.gz"
    sha256 "e66688b908ab2f05f87cc5a364f958a1351f101ccab3b3ade33a926453002f4e"

    # Fix build with FFmpeg 5. Remove in the next release.
    # Backport of upstream commit due to NULL -> nullptr changes.
    # PR ref: https://github.com/synfig/synfig/pull/2734
    patch :DATA
  end

  livecheck do
    url :stable
    regex(%r{url=.*?/synfig[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 arm64_monterey: "0cd5dc3b5382d939719fdb9ecc8e235bc497a94176f8a5325a7d6746a5d83ffa"
    sha256 arm64_big_sur:  "248a8a69404babd55d6d1e678fb2022d42639f47e7e5a8b34c92a014abbbd7ed"
    sha256 monterey:       "af48b521c6c938a7b9659ccc521a2dec3f4ee9d525b4f6cfa89e890423e7ed9d"
    sha256 big_sur:        "f85dbdbe02942899a886ad52ae90250d92eab5d9d107274f29d2f58051db47d2"
    sha256 catalina:       "5fab8763baffa4652cd3ff289ee4fad1530cd0a3dbbee0b74c17d0c52b785b4e"
    sha256 x86_64_linux:   "b6865d57013ac63ae95ee4208b993e7123390758fe195bd278b377eb2f5b8823"
  end

  head do
    url "https://github.com/synfig/synfig.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "intltool" => :build
  depends_on "pkg-config" => :build
  depends_on "boost"
  depends_on "cairo"
  depends_on "etl"
  depends_on "fftw"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "libpng"
  depends_on "libsigc++@2"
  depends_on "libtool"
  depends_on "libxml++"
  depends_on "mlt"
  depends_on "openexr"
  depends_on "pango"

  uses_from_macos "perl" => :build

  on_linux do
    depends_on "gcc"
  end

  fails_with gcc: "5"

  def install
    ENV.prepend_path "PERL5LIB", Formula["intltool"].libexec/"lib/perl5" unless OS.mac?
    ENV.cxx11

    if build.head?
      cd "synfig-core"
      system "./bootstrap.sh"
    end
    system "./configure", *std_configure_args,
                          "--disable-silent-rules",
                          "--with-boost=#{Formula["boost"].opt_prefix}",
                          "--without-jpeg"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <stddef.h>
      #include <synfig/version.h>
      int main(int argc, char *argv[])
      {
        const char *version = synfig::get_version();
        return 0;
      }
    EOS
    ENV.libxml2
    cairo = Formula["cairo"]
    etl = Formula["etl"]
    fontconfig = Formula["fontconfig"]
    freetype = Formula["freetype"]
    gettext = Formula["gettext"]
    glib = Formula["glib"]
    glibmm = Formula["glibmm@2.66"]
    libpng = Formula["libpng"]
    libsigcxx = Formula["libsigc++@2"]
    libxmlxx = Formula["libxml++"]
    mlt = Formula["mlt"]
    pango = Formula["pango"]
    pixman = Formula["pixman"]
    flags = %W[
      -I#{cairo.opt_include}/cairo
      -I#{etl.opt_include}
      -I#{fontconfig.opt_include}
      -I#{freetype.opt_include}/freetype2
      -I#{gettext.opt_include}
      -I#{glib.opt_include}/glib-2.0
      -I#{glib.opt_lib}/glib-2.0/include
      -I#{glibmm.opt_include}/giomm-2.4
      -I#{glibmm.opt_include}/glibmm-2.4
      -I#{glibmm.opt_lib}/giomm-2.4/include
      -I#{glibmm.opt_lib}/glibmm-2.4/include
      -I#{include}/synfig-1.0
      -I#{libpng.opt_include}/libpng16
      -I#{libsigcxx.opt_include}/sigc++-2.0
      -I#{libsigcxx.opt_lib}/sigc++-2.0/include
      -I#{libxmlxx.opt_include}/libxml++-2.6
      -I#{libxmlxx.opt_lib}/libxml++-2.6/include
      -I#{mlt.opt_include}/mlt-7
      -I#{pango.opt_include}/pango-1.0
      -I#{pixman.opt_include}/pixman-1
      -D_REENTRANT
      -L#{cairo.opt_lib}
      -L#{gettext.opt_lib}
      -L#{glib.opt_lib}
      -L#{glibmm.opt_lib}
      -L#{libsigcxx.opt_lib}
      -L#{libxmlxx.opt_lib}
      -L#{lib}
      -L#{mlt.opt_lib}
      -L#{pango.opt_lib}
      -lcairo
      -lgio-2.0
      -lgiomm-2.4
      -lglib-2.0
      -lglibmm-2.4
      -lgobject-2.0
      -lmlt-7
      -lmlt++-7
      -lpango-1.0
      -lpangocairo-1.0
      -lpthread
      -lsigc-2.0
      -lsynfig
      -lxml++-2.6
      -lxml2
    ]
    flags << "-lintl" if OS.mac?
    system ENV.cxx, "-std=c++11", "test.cpp", "-o", "test", *flags
    system "./test"
  end
end

__END__
--- a/src/modules/mod_libavcodec/trgt_av.cpp
+++ b/src/modules/mod_libavcodec/trgt_av.cpp
@@ -41,6 +41,7 @@
 extern "C"
 {
 #ifdef HAVE_LIBAVFORMAT_AVFORMAT_H
+#	include <libavcodec/avcodec.h>
 #	include <libavformat/avformat.h>
 #elif defined(HAVE_AVFORMAT_H)
 #	include <avformat.h>
@@ -234,12 +235,14 @@ class Target_LibAVCodec::Internal
 		close();

 		if (!av_registered) {
+#if LIBAVCODEC_VERSION_MAJOR < 59 // FFMPEG < 5.0
 			av_register_all();
+#endif
 			av_registered = true;
 		}

 		// guess format
-		AVOutputFormat *format = av_guess_format(NULL, filename.c_str(), NULL);
+		const AVOutputFormat *format = av_guess_format(NULL, filename.c_str(), NULL);
 		if (!format) {
 			synfig::warning("Target_LibAVCodec: unable to guess the output format, defaulting to MPEG");
 			format = av_guess_format("mpeg", NULL, NULL);
@@ -254,6 +257,7 @@ class Target_LibAVCodec::Internal
 		context = avformat_alloc_context();
 		assert(context);
 		context->oformat = format;
+#if LIBAVCODEC_VERSION_MAJOR < 59 // FFMPEG < 5.0
 		if (filename.size() + 1 > sizeof(context->filename)) {
 			synfig::error(
 				"Target_LibAVCodec: filename too long, max length is %d, filename is '%s'",
@@ -263,6 +267,14 @@ class Target_LibAVCodec::Internal
 			return false;
 		}
 		memcpy(context->filename, filename.c_str(), filename.size() + 1);
+#else
+		context->url = av_strndup(filename.c_str(), filename.size());
+		if (!context->url) {
+			synfig::error("Target_LibAVCodec: cannot allocate space for filename");
+			close();
+			return false;
+		}
+#endif

 		packet = av_packet_alloc();
 		assert(packet);
