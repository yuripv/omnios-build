#!/usr/bin/bash
#
# {{{ CDDL HEADER
#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source. A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
# }}}
#
# Copyright 2023 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/build.sh

PROG=nspr
VER=4.35
PKG=library/nspr
SUMMARY="Netscape Portable Runtime"
DESC="The $SUMMARY"

set_ssp none
# required for getopt
set_standard XPG6

XFORM_ARGS+=" -DPREFIX=${PREFIX#/}"

CTF_FLAGS+=" -s"
SKIP_RTIME_CHECK=1

pre_configure() {
    typeset arch=$1

    case $arch in
        amd64)  LIBDIR="$PREFIX/lib/mps/amd64" ;;
        *)      LIBDIR="$PREFIX/lib/mps" ;;
    esac

    CONFIGURE_OPTS="
        --libdir=$LIBDIR
        --includedir=/usr/include/mps
        --disable-debug
        --enable-optimize
    "
    CONFIGURE_OPTS[amd64]+=" --enable-64bit"

    if cross_arch $arch; then
        CONFIGURE_OPTS+=" HOST_CC=/opt/gcc-$DEFAULT_GCC_VER/bin/gcc"
    fi
}

post_install() {
    # Fix up the .pc files so that they include the required -R ld flag
    $FD -e pc . $DESTDIR/$LIBDIR | while read a; do
        logmsg "-- fixing up ${a##*/}"
        logcmd sed -i -E 's^-L/([^ ]*)^& -R/\1^' $a
    done

    manifest_start $TMPDIR/manifest.nspr.header
    manifest_add_dir $PREFIX/include/mps md obsolete private
    manifest_finalise $TMPDIR/manifest.nspr.header $PREFIX

    manifest_uniq $TMPDIR/manifest.nspr{,.header}
    manifest_finalise $TMPDIR/manifest.nspr $PREFIX
}

init
download_source $PROG $PROG $VER
append_builddir $PROG
patch_source
prep_build
build

###########################################################################

make_package -seed $TMPDIR/manifest.nspr

PKG=library/nspr/header-nspr
SUMMARY+=" (headers)"
DESC+=" (headers)"
make_package -seed $TMPDIR/manifest.nspr.header

###########################################################################

clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
