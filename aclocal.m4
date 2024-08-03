#
# Include the TEA standard macro set
#

builtin(include,tclconfig/tcl.m4)

#
# Add here whatever m4 macros you want to define for your package
#

AC_DEFUN([COOKBOX_FIND_STATIC_TCL_PACKAGE], [
    pkgname="$1"
    unset pkglib

    AC_MSG_CHECKING([for Tcl static package "$pkgname"])

    list=" \
        `ls -1 ${TCL_PREFIX}/lib/${pkgname}*/lib*${pkgname}*     2>/dev/null` \
        `ls -1 ${TCL_BIN_DIR}/../lib/${pkgname}*/lib*${pkgname}* 2>/dev/null`"
    for i in $list ; do
        if test -f "$i" ; then
            pkglib="$i"
            break
        fi
    done

    if test -z "${pkglib}" ; then
        AC_MSG_ERROR([Cannot find the static package.])
    fi

    TEA_ADD_LIBS([\"`${CYGPATH} ${pkglib}`\"])
    AC_MSG_RESULT([${pkglib}])
])

AC_DEFUN([COOKGOX_SET_LDFLAGS], [

    AC_REQUIRE([TEA_ENABLE_SYMBOLS])

    _LDFLAGS="$LDFLAGS"
    _CFLAGS="$CFLAGS"
    LDFLAGS="-Wl,-Map=conftest.map"
    CFLAGS=
    AC_MSG_CHECKING([whether LD supports -Wl,-Map=])
    AC_LINK_IFELSE([AC_LANG_PROGRAM([])],[
        AC_MSG_RESULT([yes])
        LDFLAGS="$_LDFLAGS -Wl,-Map=\[$]@.map"
    ],[
        AC_MSG_RESULT([no])
        LDFLAGS="$_LDFLAGS"
    ])
    CFLAGS="$_CFLAGS"

    _LDFLAGS="$LDFLAGS"
    _CFLAGS="$CFLAGS"
    LDFLAGS="-Wl,--gc-sections"
    CFLAGS=
    AC_MSG_CHECKING([whether LD supports -Wl,--gc-sections])
    AC_LINK_IFELSE([AC_LANG_PROGRAM([])],[
        AC_MSG_RESULT([yes])
        LDFLAGS="$_LDFLAGS -Wl,--gc-sections -Wl,--as-needed"
    ],[
        AC_MSG_RESULT([no])
        LDFLAGS="$_LDFLAGS"
    ])
    CFLAGS="$_CFLAGS"

    AC_MSG_CHECKING([whether to enable strip])
    if test "${CFLAGS_DEFAULT}" != "${CFLAGS_DEBUG}"; then

        AC_MSG_RESULT([yes])
        # Test this only on MacOS as GNU ld interprets -dead_strip
        # as '-de'+'ad_strip'
        if test "$SHLIB_SUFFIX" = ".dylib"; then
            _LDFLAGS="$LDFLAGS"
            _CFLAGS="$CFLAGS"
            LDFLAGS="-Wl,-dead_strip"
            CFLAGS=
            AC_MSG_CHECKING([whether LD supports -Wl,-dead_strip])
            AC_LINK_IFELSE([AC_LANG_PROGRAM([])],[
                AC_MSG_RESULT([yes])
                LDFLAGS="$_LDFLAGS -Wl,-dead_strip,-x,-S"
            ],[
                AC_MSG_RESULT([no])
                LDFLAGS="$_LDFLAGS"
            ])
            CFLAGS="$_CFLAGS"
        fi

        _LDFLAGS="$LDFLAGS"
        _CFLAGS="$CFLAGS"
        LDFLAGS="-s"
        CFLAGS=
        AC_MSG_CHECKING([whether LD supports -s])
        AC_LINK_IFELSE([AC_LANG_PROGRAM([])],[
            AC_MSG_RESULT([yes])
            LDFLAGS="$_LDFLAGS -s"
        ],[
            AC_MSG_RESULT([no])
            LDFLAGS="$_LDFLAGS"
        ])
        CFLAGS="$_CFLAGS"

    else
        AC_MSG_RESULT([no])
    fi

])
