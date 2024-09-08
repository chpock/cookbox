# main.tcl - cookbox main script
#
# Copyright (c) 2024 Konstantin Kushnir <chpock@gmail.com>
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

package require cookfs
package require cookbox

source [file join [file dirname [info script]] "args.tcl"]

# Unfortunatelly, Tcl corrupts command line arguments for scripts.
# The best we can do is to parse the command line in the main.c file.
# However, to make things easier, we are going to try to restore
# the command line here. We will try to compare the tail of
# the filename in $argv0 with [info nameofexecutable]. If they match
# we consider the command line to be empty. If they don't match, then
# $argv0 contains our first command line argument.

if { [file tail $argv0] ne [file tail [info nameofexecutable]] } {
    set argv [linsert $argv 0 $argv0]
}
set argv0 [info nameofexecutable]

set cmd [file tail $argv0]

proc op-catenate { options } {

    if { ![dict exists $options file] } {
        show_usage "Refusing to write archive contents to terminal (missing -f option?)"
    }

    set archive [dict get $options file]

    if { ![file isfile $archive] } {
        show_error "$archive: File does not exist"
    }

    set files [dict get $options -]

    cookfs::Mount $archive $archive {*}[dict get $options cookfs_opts]

    if { [dict exists $options "directory"] } {
        cd [dict get $options "directory"]
    }

    foreach file $files {
        if { ![file isfile $file] } {
            show_error "$file: File does not exist or is not a file"
        }
        cookfs::Mount $file $file -readonly {*}[dict get $options cookfs_opts]
        foreach local_file [glob -nocomplain -directory $file *] {
            file copy -force -- $local_file $archive
        }
        cookfs::Unmount $file
    }
    cookfs::Unmount $archive

}

proc op-create { options } {

    if { ![dict exists $options file] } {
        show_usage "Refusing to write archive contents to terminal (missing -f option?)"
    }

    set files [dict get $options -]
    if { ![llength $files] } {
        show_usage "Cowardly refusing to create an empty archive"
    }

    set archive [dict get $options file]

    if { [file exists $archive] && ![file isfile $archive] } {
        show_error "$archive: Is not a file"
    }
    file delete -force -- $archive

    cookfs::Mount $archive $archive {*}[dict get $options cookfs_opts]

    if { [dict exists $options "directory"] } {
        cd [dict get $options "directory"]
    }

    foreach file $files {
        if { [dict get $options verbose] } {
            puts "$file"
        }
        set split [file split $file]
        if { [llength $split] == 1 } {
            file copy -force -- $file $archive
        } else {
            if { [file pathtype $file] ne "relative" } {
                # strip root from absolute filename
                set split [lreplace $split 0 0]
            }
            file mkdir [file join $archive {*}[lrange $split 0 end-1]]
            file copy -force -- $file [file join $archive {*}[lrange $split 0 end-1]]
        }
    }

    cookfs::Unmount $archive

}

proc op-cookinize { options } {

    if { ![dict exists $options file] } {
        show_usage "Refusing to write archive contents to terminal (missing -f option?)"
    }

    set files [dict get $options -]
    if { ![llength $files] } {
        show_usage "Cowardly refusing to create an empty archive"
    }

    set archive [dict get $options file]
    if { [file exists $archive] && ![file isfile $archive] } {
        show_error "$archive: Is not a file"
    }

    file delete -force -- $archive

    # Initialize archive with tclsh executable
    set pg [::cookfs::c::pages -readonly [info nameofexecutable]]
    set head [$pg gethead]
    $pg delete

    set fh [open $archive w]
    fconfigure $fh -translation binary
    puts -nonewline $fh $head
    close $fh

    cookfs::Mount $archive $archive {*}[dict get $options cookfs_opts]

    file copy -force "//cookfs:/lib" $archive

    if { [dict exists $options "directory"] } {
        cd [dict get $options "directory"]
    }

    foreach file $files {
        if { [dict get $options verbose] } {
            puts "$file"
        }
        set split [file split $file]
        if { [llength $split] == 1 } {
            file copy -force -- $file $archive
        } else {
            if { [file pathtype $file] ne "relative" } {
                # strip root from absolute filename
                set split [lreplace $split 0 0]
            }
            file mkdir [file join $archive {*}[lrange $split 0 end-1]]
            file copy -force -- $file [file join $archive {*}[lrange $split 0 end-1]]
        }
    }

    cookfs::Unmount $archive

    file attributes $archive -permissions 0o0744

}

proc op-diff { options } {
    invalid_not_implemented "diff"
}

proc op-delete { options } {

    if { ![dict exists $options file] } {
        show_usage "Refusing to read archive contents from terminal (missing -f option?)"
    }

    set archive [dict get $options file]

    if { ![file isfile $archive] } {
        show_error "$archive: File does not exist"
    }

    set files [dict get $options -]

    cookfs::Mount $archive $archive {*}[dict get $options cookfs_opts]

    if { [dict exists $options "directory"] } {
        cd [dict get $options "directory"]
    }

    foreach file $files {
        if { [file pathtype $file] ne "relative" } {
            show_error "$file: Is not a relative file name"
        }
        if { ![file exists [file join $archive $file]] } {
            show_error "$file: Not found in archive"
        }
        file delete -force -- [file join $archive $file]
    }

    cookfs::Unmount $archive

}

proc op-append { options } {

    if { ![dict exists $options file] } {
        show_usage "Refusing to write archive contents to terminal (missing -f option?)"
    }

    set files [dict get $options -]

    set archive [dict get $options file]

    cookfs::Mount $archive $archive {*}[dict get $options cookfs_opts]

    if { [dict exists $options "directory"] } {
        cd [dict get $options "directory"]
    }

    foreach file $files {
        if { [dict get $options verbose] } {
            puts "$file"
        }
        set split [file split $file]
        if { [llength $split] == 1 } {
            file copy -force -- $file $archive
        } else {
            if { [file pathtype $file] ne "relative" } {
                # strip root from absolute filename
                set split [lreplace $split 0 0]
            }
            file mkdir [file join $archive {*}[lrange $split 0 end-1]]
            file copy -force -- $file [file join $archive {*}[lrange $split 0 end-1]]
        }
    }

    cookfs::Unmount $archive

}

proc op-list { options } {

    if { ![dict exists $options file] } {
        show_usage "Refusing to read archive contents from terminal (missing -f option?)"
    }

    set archive [dict get $options file]

    if { ![file isfile $archive] } {
        show_error "$archive: File does not exist"
    }

    set glob [list apply {{ glob archive path } {
        foreach filename [glob -nocomplain -directory [file join $archive $path] -tails *] {
            if { ![file isdirectory [file join $archive $path $filename]] } {
                puts [file join $path $filename]
                continue
            }
            puts "[file join $path $filename]/"
            {*}$glob $glob $archive [file join $path $filename]
        }
    }}]
    lappend glob $glob $archive

    cookfs::Mount $archive $archive -readonly {*}[dict get $options cookfs_opts]

    if { [dict exists $options "directory"] } {
        cd [dict get $options "directory"]
    }

    {*}$glob ""

    cookfs::Unmount $archive

}

proc op-test-label { options } {
    invalid_not_implemented "test-label"
}

proc op-update { options } {
    invalid_not_implemented "update"
}

proc op-extract { options } {

    if { ![dict exists $options file] } {
        show_usage "Refusing to read archive contents from terminal (missing -f option?)"
    }

    set archive [dict get $options file]

    if { ![file isfile $archive] } {
        show_error "$archive: File does not exist"
    }

    set files [dict get $options -]

    cookfs::Mount $archive $archive -readonly {*}[dict get $options cookfs_opts]

    if { [dict exists $options "directory"] } {
        cd [dict get $options "directory"]
    }

    if { ![llength $files] } {
        set files [glob -nocomplain -directory $archive -tails *]
    }

    foreach file $files {
        if { [file pathtype $file] ne "relative" } {
            show_error "$file: Is not a relative file name"
        }
        if { ![file exists [file join $archive $file]] } {
            show_error "$file: Not found in archive"
        }
        if { [dict get $options verbose] } {
            puts "$file"
        }
        set split [file split $file]
        if { [llength $split] == 1 } {
            file copy -force -- [file join $archive $file] .
        } else {
            file mkdir [file join . {*}[lrange $split 0 end-1]]
            file copy -force -- [file join $archive $file] [file join . {*}[lrange $split 0 end-1]]
        }

    }

    cookfs::Unmount $archive

}

proc op-show-defaults { options } {
    invalid_not_implemented "show-defaults"
}

proc op-help { options } {
    puts [subst -nocommands -nobackslashes [string trim {

Usage: $::cmd [OPTION...] [FILE]...
cookbox saves many files together into a single disk archive, and can restore individual files from the archive.

Examples:
  $::cmd -cf archive.cookfs foo bar  # Create archive.cookfs from files foo and bar.
  $::cmd -tvf archive.cookfs         # List all files in archive.cookfs verbosely.
  $::cmd -xf archive.cookfs          # Extract all files from archive.cookfs.

 Main operation mode:
  -A, --catenate, --concatenate   append cookfs files to an archive
  -c, --create               create a new archive
      --delete               delete from the archive
  -r, --append               append files to the end of an archive
  -t, --list                 list the contents of an archive
  -x, --extract, --get       extract files from an archive
      --analyze              analyze an archive
      --cookinize            wrap files to an executable
      --shell                run interactive Tcl shell
      --eval                 evaluate the provided script or file

 Local file name selection:
  -C, --directory=DIR        change to directory DIR

 Archive options:
      --pagesize=SIZE        specifies maximum size of a page in bytes
      --smallfilesize=SIZE   specifies threshold for small files in bytes
      --smallfilebuffer=SIZE specifies maximum buffer for small files in bytes

 Compression options:
      --no-compression       don't use any compression
  -j, --bzip2                use bzip2 compression
  -J, --xz, --lzma           use LZMA compression
      --zstd                 use Zstandard compression
  -z, --gzip, --gunzip, --ungzip   use zlib compression
      --brotli               use brotli compression
      --compression-level=LEVEL use LEVEL compression level

 Encryption options:
      --encryptkey           use key-based encryption
      --encryptlevel=LEVEL   specifies the encryption level
      --password=SECRET      specifies the password to be used for encryption

 Informative output:

  -v, --verbose              verbosely list files processed

 Other options:

  -?, --help                 give this help list
      --usage                give a short usage message
      --version              print program version

}]]
}

proc op-usage { options } {
    puts [subst -nocommands -nobackslashes [string trim {

Usage: $::cmd [-cxt] [--help] [--usage] [--version] [FILE]...

}]]
    exit 0
}

proc op-version { options } {
    puts "cookbox [::cookbox::version] (with cookfs [cookfs::pkgconfig get package-version])"
    puts "Copyright (C) 2024 Konstantin Kushnir <chpock@gmail.com>"
    puts "Distributed under the terms of the Tcl/Tk license: <https://tcl.tk/software/tcltk/license.html>"
    exit 0
}

proc op-shell { options } {
    package require TclReadLine
    TclReadLine::interact
}

proc op-eval { options } {
    if { [dict exists $options file] } {
        source [dict get $options file]
    } else {
        eval [lindex [dict get $options "-"] 0]
    }
}

if { ![llength $argv] } {
    invalid_usage
}

# Convert traditional arguments style to GNU
if { [string index [lindex $argv 0] 0] ne "-" } {
    set argv [traditional2GNU [lindex $argv 0] {*}[lrange $argv 1 end]]
}

set options [dict create {*}{
    verbose 0
}]

set options [dict merge $options [parse_args {*}$argv]]

# Process cookfs options

set cookfs_opts [dict create]

unset -nocomplain compression

if { [dict exists $options bzip2] } {
    set compression "bzip2"
} elseif { [dict exists $options xz] } {
    set compression "lzma"
} elseif { [dict exists $options lzma] } {
    set compression "lzma"
} elseif { [dict exists $options zstd] } {
    set compression "zstd"
} elseif { [dict exists $options gzip] } {
    set compression "zlib"
} elseif { [dict exists $options brotli] } {
    set compression "brotli"
} elseif { [dict exists $options no-compression] } {
    set compression "none"
}

if { [dict exists $options compression-level] } {
    if { ![info exists compression] } {
        set compression "lzma"
    }
    set compression "${compression}:[dict get $options compression-level]"
}

if { [info exists compression] } {
    lappend cookfs_opts -compression $compression
}

if { [dict exists $options pagesize] } {
    lappend cookfs_opts -pagesize [dict get $options pagesize]
}

if { [dict exists $options smallfilesize] } {
    lappend cookfs_opts -smallfilesize [dict get $options smallfilesize]
}

if { [dict exists $options smallfilebuffer] } {
    lappend cookfs_opts -smallfilesize [dict get $options smallfilebuffer]
}

if { [dict exists $options encryptlevel] } {
    lappend cookfs_opts -encryptlevel [dict get $options encryptlevel]
}

if { [dict exists $options password] } {
    lappend cookfs_opts -encryptlevel [dict get $options password]
}

if { [dict exists $options encryptkey] } {
    lappend cookfs_opts -encryptkey
}

dict set options cookfs_opts $cookfs_opts

# Invoke operation
op-[dict get $options operation] $options
