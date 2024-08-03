/* cookbox - main app

 Copyright (C) 2024 Konstantin Kushnir <chpock@gmail.com>
 */

#include <tcl.h>
#include <tclCookfs.h>

#ifdef __WIN32__
#define WIN32_LEAN_AND_MEAN
#ifndef STRICT
#define STRICT // See MSDN Article Q83456
#endif /* STRICT */
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN
#include <tchar.h>
#endif

#define VFS_MOUNT "//cookfs:/"

#ifdef __WIN32__
#define NULL_DEVICE "NUL"
#else
#define NULL_DEVICE "/dev/null"
#endif /* __WIN32__ */

#ifndef STRINGIFY
#  define STRINGIFY(x) STRINGIFY1(x)
#  define STRINGIFY1(x) #x
#endif

static int Cookbox_VersionCmd(ClientData clientData,
    Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
    (void)clientData;
    (void)objc;
    (void)objv;
    Tcl_SetObjResult(interp, Tcl_NewStringObj(PACKAGE_VERSION, -1));
    return TCL_OK;
}

static int Cookbox_Startup(Tcl_Interp *interp) {

    // Make sure that we have stdout/stderr/stdin channels. Initialize them
    // to /dev/null if we don't have any. This will prevent Tcl from crashing
    // when attempting to write/read from standard channels.
    Tcl_Channel chan;

    chan = Tcl_GetStdChannel(TCL_STDIN);
    if (!chan) {
        chan = Tcl_OpenFileChannel(interp, NULL_DEVICE, "r", 0);
        if (chan) {
            Tcl_SetChannelOption(interp, chan, "-encoding", "utf-8");
            Tcl_SetStdChannel(chan, TCL_STDIN);
        }
    }

    chan = Tcl_GetStdChannel(TCL_STDOUT);
    if (!chan) {
        chan = Tcl_OpenFileChannel(interp, NULL_DEVICE, "w", 0);
        if (chan) {
            Tcl_SetChannelOption(interp, chan, "-encoding", "utf-8");
            Tcl_SetStdChannel(chan, TCL_STDOUT);
        }
    }

    chan = Tcl_GetStdChannel(TCL_STDERR);
    if (!chan) {
        chan = Tcl_OpenFileChannel(interp, NULL_DEVICE, "w", 0);
        if (chan) {
            Tcl_SetChannelOption(interp, chan, "-encoding", "utf-8");
            Tcl_SetStdChannel(chan, TCL_STDERR);
        }
    }

    // Register cookfs package in Tcl interp
    Tcl_StaticPackage(0, "Cookfs", Cookfs_Init, NULL);

    // Load cookfs package
    if (Cookfs_Init(interp) != TCL_OK) {
        Tcl_SetObjResult(interp, Tcl_NewStringObj("failed to init cookfs"
            " package", -1));
        goto error;
    }

    // Define mount point for cookfs VFS
    Tcl_Obj *local = Tcl_NewStringObj(VFS_MOUNT, -1);
    Tcl_IncrRefCount(local);

    // Get the name of our executable file
    Tcl_Obj *exename = Tcl_NewStringObj(Tcl_GetNameOfExecutable(), -1);
    Tcl_IncrRefCount(exename);

    // Configure properties for root VFS
    void *props = Cookfs_VfsPropsInit();
    Cookfs_VfsPropSetVolume(props, 1);
    Cookfs_VfsPropSetReadonly(props, 1);
#ifdef TCL_THREADS
    Cookfs_VfsPropSetShared(props, 1);
#endif /* TCL_THREADS */

    int isVFSAvailable = Cookfs_Mount(interp, exename, local, props) == TCL_OK
        ? 1 : 0;

    // Release resources
    Cookfs_VfsPropsFree(props);
    Tcl_DecrRefCount(exename);
    Tcl_DecrRefCount(local);

    // If cookfs is successfully mounted, then use the Tcl runtime environment
    // from this VFS. It is not, then assume we are in bootstrap more and run
    // Tcl interp as is.
    if (isVFSAvailable) {
        // Instruct the Tcl core to look for packages in cookfs.
        Tcl_PutEnv("TCL_LIBRARY=" VFS_MOUNT "lib/tcl" TCL_VERSION);
        // Ignore the TCLLIBPATH environment variable when searching for packages.
        // We cannot do just Tcl_PutEnv("TCLLIBPATH=") here. In this case,
        // [info exists env(TCLLIBPATH)] will be true, but accessing $env(TCLLIBPATH)
        // element array results in a "no such variable" error.
        // Thus, here we will unset the array element.
        Tcl_UnsetVar2(interp, "env", "TCLLIBPATH", TCL_GLOBAL_ONLY);
        // Use main.tcl script as our main code
        Tcl_SetStartupScript(Tcl_NewStringObj(VFS_MOUNT "main.tcl", -1), NULL);
        // Here is an example how to define our small command
        Tcl_CreateNamespace(interp, "::cookbox", NULL, NULL);
        Tcl_CreateObjCommand(interp, "::cookbox::version", Cookbox_VersionCmd,
            (ClientData) NULL, NULL);
    }

    if (Tcl_Init(interp) != TCL_OK) {
        goto error;
    }

    return TCL_OK;

error:

    return TCL_ERROR;

}

#ifdef __WIN32__
int _tmain(int argc, TCHAR *argv[]) {
#else
int main(int argc, char **argv) {
#endif /* __WIN32__ */
    Tcl_Main(argc, argv, Cookbox_Startup);
    return 0;
}
