# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python2_7 )
inherit multiprocessing pax-utils python-any-r1 qt5-build

DESCRIPTION="Library for rendering dynamic web content in Qt5 C++ and QML applications"

if [[ ${QT5_BUILD_TYPE} == release ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

SRC_URI+=" system-icu? (
	https://dev.gentoo.org/~chiitoo/distfiles/qtwebengine-5.11.0-system-icu-patch.tar.bz2
)"

IUSE="alsa bindist geolocation pax_kernel pulseaudio +system-ffmpeg +system-icu widgets"

RDEPEND="
	app-arch/snappy:=
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	~dev-qt/qtcore-${PV}
	~dev-qt/qtdeclarative-${PV}
	~dev-qt/qtgui-${PV}
	~dev-qt/qtnetwork-${PV}
	~dev-qt/qtprintsupport-${PV}
	~dev-qt/qtwebchannel-${PV}[qml]
	dev-libs/expat
	dev-libs/libevent:=
	dev-libs/libxml2[icu]
	dev-libs/libxslt
	dev-libs/protobuf:=
	dev-libs/re2:=
	media-libs/fontconfig
	media-libs/freetype
	media-libs/harfbuzz:=
	media-libs/libjpeg-turbo:=
	media-libs/libpng:0=
	>=media-libs/libvpx-1.5:=[svc]
	media-libs/libwebp:=
	media-libs/mesa
	media-libs/opus
	net-libs/libsrtp:0=
	sys-apps/dbus
	sys-apps/pciutils
	sys-libs/libcap
	sys-libs/zlib[minizip]
	virtual/jpeg:0
	virtual/libudev
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	alsa? ( media-libs/alsa-lib )
	geolocation? ( ~dev-qt/qtpositioning-${PV} )
	pulseaudio? ( media-sound/pulseaudio:= )
	system-ffmpeg? ( media-video/ffmpeg:0= )
	system-icu? ( dev-libs/icu:= )
	widgets? (
		~dev-qt/qtdeclarative-${PV}[widgets]
		~dev-qt/qtwidgets-${PV}
	)
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	>=app-arch/gzip-1.7
	dev-util/gperf
	dev-util/ninja
	dev-util/re2c
	sys-devel/bison
	pax_kernel? ( sys-apps/elfix )
"

src_prepare() {
	use pax_kernel && PATCHES+=( "${FILESDIR}/${PN}-5.9.3-paxmark-mksnapshot.patch" )
	use system-icu && has_version ">=dev-libs/icu-59" && \
		PATCHES+=( "${WORKDIR}/${PN}-5.11.0-fix-system-icu.patch" )

	# bug 620444 - ensure local headers are used
	find "${S}" -type f -name "*.pr[fio]" | xargs sed -i -e 's|INCLUDEPATH += |&$$QTWEBENGINE_ROOT/include |' || die

	qt_use_disable_config alsa webengine-alsa src/core/config/linux.pri
	qt_use_disable_config pulseaudio webengine-pulseaudio src/core/config/linux.pri

	qt_use_disable_mod geolocation positioning \
		mkspecs/features/configure.prf \
		src/core/core_chromium.pri \
		src/core/core_common.pri

	qt_use_disable_mod widgets widgets src/src.pro

	qt5-build_src_prepare
}

src_configure() {
	export NINJA_PATH=/usr/bin/ninja
	export NINJAFLAGS="${NINJAFLAGS:--j$(makeopts_jobs) -l$(makeopts_loadavg "${MAKEOPTS}" 0) -v}"

	local myqmakeargs=(
		--
		-opus
		-printing-and-pdf
		-webp
		$(usex alsa '-alsa' '')
		$(usex bindist '' '-proprietary-codecs')
		$(usex pulseaudio '-pulseaudio' '')
		$(usex system-ffmpeg '-ffmpeg' '')
		$(usex system-icu '-webengine-icu' '')
	)
	qt5-build_src_configure
}

src_install() {
	qt5-build_src_install

	# bug 601472
	if [[ ! -f ${D%/}${QT5_LIBDIR}/libQt5WebEngine.so ]]; then
		die "${CATEGORY}/${PF} failed to build anything. Please report to https://bugs.gentoo.org/"
	fi

	pax-mark m "${D%/}${QT5_LIBEXECDIR}"/QtWebEngineProcess
}
