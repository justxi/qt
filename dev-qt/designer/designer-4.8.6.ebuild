# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils qt4-build-multilib

DESCRIPTION="WYSIWYG tool for designing and building Qt-based GUIs"

if [[ ${QT4_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
fi

DESIGNER_PLUGINS="declarative phonon qt3support webkit"
IUSE="${DESIGNER_PLUGINS}"

DEPEND="
	~dev-qt/qtcore-${PV}[aqua=,debug=,${MULTILIB_USEDEP}]
	~dev-qt/qtgui-${PV}[aqua=,debug=,${MULTILIB_USEDEP}]
	~dev-qt/qtscript-${PV}[aqua=,debug=,${MULTILIB_USEDEP}]
	declarative? ( ~dev-qt/qtdeclarative-${PV}[aqua=,debug=,${MULTILIB_USEDEP}] )
	phonon? ( ~dev-qt/qtphonon-${PV}[aqua=,debug=,${MULTILIB_USEDEP}] )
	qt3support? ( ~dev-qt/qt3support-${PV}[aqua=,debug=,${MULTILIB_USEDEP}] )
	webkit? ( ~dev-qt/qtwebkit-${PV}[aqua=,debug=,${MULTILIB_USEDEP}] )
"
RDEPEND="${DEPEND}"

QT4_TARGET_DIRECTORIES="tools/designer"

src_prepare() {
	qt4-build-multilib_src_prepare

	local plugin
	for plugin in ${DESIGNER_PLUGINS}; do
		use ${plugin} || sed -i -e "/\<${plugin}\>/d" \
			tools/designer/src/plugins/plugins.pro || die
	done
}

multilib_src_configure() {
	local myconf=(
		-system-libpng -system-libjpeg -system-zlib
		-no-sql-mysql -no-sql-psql -no-sql-ibase -no-sql-sqlite -no-sql-sqlite2 -no-sql-odbc
		-sm -xshape -xsync -xcursor -xfixes -xrandr -xrender -mitshm -xinput -xkb
		-fontconfig -no-svg -no-webkit -no-phonon -no-opengl
	)
	qt4_multilib_src_configure
}

multilib_src_install() {
	qt4_multilib_src_install

	# qt-creator
	# some qt-creator headers are located
	# under /usr/include/qt4/QtDesigner/private.
	# those headers are just includes of the headers
	# which are located under tools/designer/src/lib/*
	# So instead of installing both, we create the private folder
	# and drop tools/designer/src/lib/* headers in it.
	if use aqua && [[ ${CHOST##*-darwin} -ge 9 ]]; then
		insinto "${QT4_LIBDIR#${EPREFIX}}"/QtDesigner.framework/Headers/private/
	else
		insinto "${QT4_HEADERDIR#${EPREFIX}}"/QtDesigner/private/
	fi
	doins "${S}"/tools/designer/src/lib/shared/*
	doins "${S}"/tools/designer/src/lib/sdk/*

	doicon tools/designer/src/designer/images/designer.png
	make_desktop_entry designer Designer designer 'Qt;Development;GUIDesigner'
}
