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
# Copyright (c) 2014 by Delphix. All rights reserved.
# Copyright 2022 OmniOS Community Edition (OmniOSce) Association.

. ../../lib/build.sh

PKG=system/virtualization/open-vm-tools
PROG=open-vm-tools
VER=12.0.5
# The open-vm-tools have been inconsistent in the past in regard to whether
# the filenames and extracted directories contain the build number. If they
# do, set the build number.
BUILD=19716617
SUMMARY="Open Virtual Machine Tools"
DESC="The Open Virtual Machine Tools project aims to provide a suite of open "
DESC+="source virtualisation utilities and drivers to improve the "
DESC+="functionality and user experience of virtualisation. The project "
DESC+="currently runs in guest operating systems under the VMware hypervisor."

DLVER=$VER
if [ -n "$BUILD" ]; then
    set_builddir "$PROG-$VER-$BUILD"
    DLVER+=-$BUILD
fi

export PATH=$GNUBIN:$PATH

set_arch 64
CTF_FLAGS+=" -s"

BUILD_DEPENDS_IPS='developer/pkg-config'

# XPG4v2 - Need cmsg from UNIX95
# __EXTENSIONS__ (see CFLAGS) - Need gethostbyname_r in XPG4v2
set_standard XPG4v2

NO_SONAME_EXPECTED=1

CFLAGS+="\
    -std=gnu89 \
    -Wno-logical-not-parentheses \
    -Wno-bool-compare \
    -Wno-deprecated \
    -Wno-deprecated-declarations \
    -Wno-unused-local-typedefs \
    -Wno-array-parameter \
    -D__EXTENSIONS__ \
"
CONFIGURE_OPTS="
    --without-kernel-modules
    --disable-static
    --disable-multimon
    --without-x
    --without-dnet
    --without-icu
    --without-gtk2
    --without-gtkmm
    --enable-deploypkg=no
    --disable-grabbitmqproxy
    --without-xerces
    --disable-docs
    --without-gnu-ld
"

make_prog64() {
    # Parts of the vmbackup code get generated by 'rpcgen' which adds unused
    # variables. Disable -Werror for this directory.
    # Also disable for some other directories where deprecated glib functions
    # are used.
    for dir in services/plugins/vmbackup lib/glibUtils lib/rpcChannel \
        libvmtools services/vmtoolsd; do
        logcmd sed -i 's/-Werror//g' $dir/Makefile \
            || logerr "Failed to disable -Werror in $dir"
    done
    make_prog
}

install_conf() {
    pushd $DESTDIR > /dev/null
    logcmd mkdir -p etc/vmware-tools/ || logerr "mkdir failed"
    logcmd cp $SRCDIR/files/tools.conf etc/vmware-tools/ || logerr "cp fail"
    popd > /dev/null
}

init
download_source $PROG $PROG $DLVER
patch_source
prep_build
run_autoreconf -fi
build
install_smf system/virtualization open-vm-tools.xml
install_conf
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
