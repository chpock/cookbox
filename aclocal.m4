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

    TEA_ADD_LIBS([${pkglib}])
    AC_MSG_RESULT([${pkglib}])
])
