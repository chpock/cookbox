#!/bin/sh

set -e

DEBUG=0
TRACE=0

SELF_HOME="$(cd "$(dirname "$0")"; pwd)"
BUILD_HOME="$(pwd)"
if [ "$SELF_HOME" = "$BUILD_HOME" ]; then
    BUILD_HOME="$BUILD_HOME/build"
fi
ROOT_DEPS="$BUILD_HOME/deps-root"
BUILD_DEPS="$BUILD_HOME/deps-build"

TCL_VERSION="${1:-8.6}"
TCL_SOURCE="$SELF_HOME/dependencies/tcl$TCL_VERSION"
COOKFS_SOURCE="$SELF_HOME/dependencies/cookfs"
TCL_SYSTEM=unix

if [ "$DEBUG" = "1" ]; then
    SYMBOLS_FLAGS="--enable-symbols=all"
    CFLAGS="-fsanitize=undefined -fsanitize=address"
    LDGLAGS="-fsanitize=undefined -fsanitize=address"
    export CFLAGS
    export LDFLAGS
else
    SYMBOLS_FLAGS="${SYMBOLS_FLAGS:-"--disable-symbols"}"
fi

if [ "$TRACE" = "1" ]; then
    COOKFS_FLAGS="--enable-internal-debug"
fi

if [ -n "$AC_BUILD" ]; then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --build=$AC_BUILD"
    case "$AC_BUILD" in
        *-mingw32) TCL_SYSTEM="win";;
    esac
fi

if [ -n "$AC_HOST" ]; then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --host=$AC_HOST"
fi

case "$(uname -s)" in
    CYGWIN*|MINGW*|MSYS_NT*) TCL_SYSTEM="win";;
esac

# Enable ccache if it exists to speed up the build
if [ -z "$CC" ] && command -v ccache >/dev/null 2>&1; then
    CC="ccache gcc"
    export CC
fi

if [ ! -e "$ROOT_DEPS"/include/tcl.h ]; then
    mkdir -p "$BUILD_DEPS/tcl"
    cd "$BUILD_DEPS/tcl"
    (set -x; "$TCL_SOURCE"/$TCL_SYSTEM/configure $SYMBOLS_FLAGS --prefix="$ROOT_DEPS" --disable-shared $CONFIGURE_FLAGS)
    (set -x; make all install-binaries install-libraries)
    # Tcl installs headers on Windows in scope of the install-libraries target. But on other
    # platforms, there is a separate target 'install-headers'.
    ! grep -q '^install-headers:' ./Makefile || (set -x; make install-headers)
    # Fix Tcl build for MinGW platform (libraries there are specified in wrong format)
    if [ "$TCL_SYSTEM" = "win" ]; then
        sed -i -e 's/ lib\(tcl[^.]\+\)\.a/ -l\1/g' "$ROOT_DEPS"/lib/tclConfig.sh
    fi
fi

if [ ! -e "$ROOT_DEPS"/include/tclCookfs.h ]; then
    mkdir -p "$BUILD_DEPS/cookfs"
    cd "$BUILD_DEPS/cookfs"
    (set -x; "$COOKFS_SOURCE"/configure $SYMBOLS_FLAGS --prefix="$ROOT_DEPS" --with-tcl="$ROOT_DEPS"/lib \
        $COOKFS_FLAGS --disable-shared $CONFIGURE_FLAGS \
        --enable-lzma --enable-zstd --enable-brotli)
    (set -x; make all install)
fi

set -x
cd "$BUILD_HOME"
"$SELF_HOME"/configure $SYMBOLS_FLAGS --with-tcl="$ROOT_DEPS"/lib $CONFIGURE_FLAGS
make
make test
make package
