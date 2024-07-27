#!/bin/sh

DEBUG=1
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

if [ "$DEBUG" = "1" ]; then
    SYMBOLS_FLAGS="--enable-symbols=all"
    CFLAGS="-fsanitize=undefined -fsanitize=address"
    LDGLAGS="-fsanitize=undefined -fsanitize=address"
    export CFLAGS
    export LDFLAGS
else
    SYMBOLS_FLAGS="--disable-symbols"
fi

if [ "$TRACE" = "1" ]; then
    COOKFS_FLAGS="--enable-internal-debug"
fi

# Enable ccache if it exists to speed up the build
if command -v ccache >/dev/null 2>&1; then
    [ -z "$CC" ] && CC="ccache gcc" || CC="ccache $CC"
    export CC
fi

if [ ! -e "$ROOT_DEPS"/include/tcl.h ]; then
    mkdir -p "$BUILD_DEPS/tcl"
    cd "$BUILD_DEPS/tcl"
    "$TCL_SOURCE"/unix/configure $SYMBOLS_FLAGS --prefix="$ROOT_DEPS" --disable-shared
    make all install-binaries install-libraries
    # Tcl installs headers on Windows in scope of the install-libraries target. But on other
    # platforms, there is a separate target 'install-headers'.
    ! grep -q '^install-headers:' ./Makefile || make install-headers
fi

if [ ! -e "$ROOT_DEPS"/include/tclCookfs.h ]; then
    mkdir -p "$BUILD_DEPS/cookfs"
    cd "$BUILD_DEPS/cookfs"
    "$COOKFS_SOURCE"/configure $SYMBOLS_FLAGS --prefix="$ROOT_DEPS" --with-tcl="$ROOT_DEPS"/lib \
        $COOKFS_FLAGS --disable-shared \
        --enable-lzma --enable-zstd --enable-brotli
    make all install
fi

cd "$BUILD_HOME"
"$SELF_HOME"/configure $SYMBOLS_FLAGS --with-tcl="$ROOT_DEPS"/lib
make
