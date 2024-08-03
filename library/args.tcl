# args.tcl - parse args
#
# Copyright (c) 2024 Konstantin Kushnir <chpock@gmail.com>
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

set format {
    ! A --catenate --concatenate
    ! c --create
    ! d --diff --compare
    !   --delete
    ! r --append
    ! t --list
    !   --test-label
    ! u --update
    ! x --extract --get
    !   --show-defaults
    ! ? --help
    !   --usage
    !   --version
    0   --check-device
    1 g --listed-incremental
    1   --hole-detection
    0 G --incremental
    0   --ignore-failed-read
    1   --level
    0 n --seek
    0   --no-check-device
    0   --no-seek
    1   --occurrence
    0   --restrict
    1   --sparse-version
    0 S --sparse
    0 k --keep-old-files
    0   --keep-newer-files
    0   --keep-directory-symlink
    0   --no-overwrite-dir
    1   --one-top-level
    0   --overwrite
    0   --overwrite-dir
    0   --recursive-unlink
    0   --remove-files
    0   --skip-old-files
    0 U --unlink-first
    0 W --verify
    0   --ignore-command-error
    0   --no-ignore-command-error
    0 O --to-stdout
    1   --to-command
    1   --atime-preserve
    0   --delay-directory-restore
    1   --group
    1   --group-map
    1   --mode
    1   --mtime
    0 m --touch
    0   --no-delay-directory-restore
    0   --no-same-owner
    0   --no-same-permissions
    0   --numeric-owner
    1   --owner
    1   --owner-map
    0 p --preserve-permissions --same-permissions
    0   --same-owner
    0 s --preserve-order --same-order
    1   --sort
    0   --acls
    0   --no-acls
    0   --selinux
    0   --no-selinux
    0   --xattrs
    0   --no-xattrs
    1   --xattrs-exclude
    1   --xattrs-include
    1 f --file
    0   --force-local
    1 F --info-script --new-volume-script
    1 L --tape-length
    0 M --multi-volume
    1   --rmt-command
    1   --rsh-command
    1   --volno-file
    1 b --blocking-factor
    0 B --read-full-records
    0 i --ignore-zeros
    1   --record-size
    1 H --format
    0   --old-archive --portability
    1   --pax-option
    0   --posix
    1 V --label
    0 a --auto-compress
    1 I --use-compress-program
    0 j --bzip2
    0 J --xz
    0   --lzip
    0   --lzma
    0   --lzop
    0   --no-auto-compress
    0 z --gzip --gunzip --ungzip
    0 Z --compress --uncompress
    0   --zstd
    1   --add-file
    1   --backup
    1 C --directory
    1   --exclude
    0   --exclude-backups
    0   --exclude-caches
    0   --exclude-caches-all
    0   --exclude-caches-under
    1   --exclude-ignore
    1   --exclude-ignore-recursive
    1   --exclude-tag
    1   --exclude-tag-all
    1   --exclude-tag-under
    0   --exclude-vcs
    0   --exclude-vcs-ignores
    0 h --dereference
    0   --hard-dereference
    1 K --starting-file
    1   --newer-mtime
    0   --no-null
    0   --no-recursion
    0   --no-unquote
    0   --no-verbatim-files-from
    0   --null
    1 N --newer --after-date
    0   --one-file-system
    0 P --absolute-names
    0   --recursion
    1   --suffix
    1 T --files-from
    0   --unquote
    0   --verbatim-files-from
    1 X --exclude-from
    1   --strip-components
    1   --transform --xform
    0   --anchored
    0   --ignore-case
    0   --no-anchored
    0   --no-ignore-case
    0   --no-wildcards
    0   --no-wildcards-match-slash
    0   --wildcards
    0   --wildcards-match-slash
    1   --checkpoint
    1   --checkpoint-action
    0   --clamp-mtime
    0   --full-time
    1   --index-file
    0 l --check-links
    1   --no-quote-chars
    1   --quote-chars
    1   --quoting-style
    0 R --block-number
    0   --show-omitted-dirs
    0   --show-transformed-names --show-stored-names
    1   --totals
    0   --utc
    0 v --verbose
    1   --warning
    0 w --interactive --confirmation
    0 o
    - { cookfs-specific options }
    !   --analyze
    !   --cookinize
    !   --shell --tclsh
    !   --eval
    1   --pagesize
    1   --smallfilesize
    1   --smallfilebuffer
    0   --brotli
    0   --no-compression
    1   --compression-level
    0   --encryptkey
    1   --encryptlevel
    1   --password
}

proc show_error { msg } {
    puts stderr "$::cmd: $msg"
    exit 1
}

proc show_usage { msg } {
    show_error [join [list \
        $msg \
        "Try '$::cmd --help' or '$::cmd --usage' for more information." \
    ] \n]
}

proc invalid_option { opt } {
    show_usage "invalid option -- '$opt'"
}

proc invalid_usage { } {
    show_usage "You must specify one of the '-Acdtrux', '--delete' or '--test-label' options"
}

proc invalid_operation { } {
    show_usage "You may not specify more than one '-Acdtrux', '--delete' or  '--test-label' option"
}

proc invalid_no_argument { opt } {
    show_usage "option '$opt' requires an argument."
}

proc invalid_not_implemented { operation } {
    show_usage "operation '$operation' has not yet been implemented."
}

proc get_arg { opt } {
    for { set i 0 } { $i < [llength $::format] } { incr i } {
        set word [lindex $::format $i]
        switch -exact $word {
            ! { set type "operation" }
            0 { set type "switch" }
            1 { set type "option" }
            - {
                incr i
                continue
            }
        }
        set short ""
        set long [list]
        for { incr i } { $i < [llength $::format] } { incr i } {
            set word [lindex $::format $i]
            if { $word in {- ! 0 1} } {
                # step back
                incr i -1
                break
            }
            if { [string length $word] == 1 } {
                set short $word
            } else {
                lappend long $word
            }
        }
        if { [string length $opt] == 1 } {
            if { $short ne $opt } {
                continue
            }
        } else {
            if { $opt ni $long } {
                continue
            }
        }
        return [dict create type $type short $short long $long]
    }
    invalid_option $opt
}

proc traditional2GNU { options args } {

    set rc [list]

    set operation [string index $options 0]
    set options   [string range $options 1 end]

    set operation [get_arg $operation]

    if { [dict get $operation type] ne "operation" } {
        invalid_usage
    }

    lappend rc [lindex [dict get $operation long] 0]

    set idx 0
    foreach opt [split $options ""] {
        set arg [get_arg $opt]
        switch -exact -- [dict get $arg type] {
            "operation" {
                invalid_operation
            }
            "switch" {
                lappend rc [lindex [dict get $arg long] 0]
            }
            "option" {
                if { $idx >= [llength $args] } {
                    invalid_no_argument $opt
                }
                lappend rc [lindex [dict get $arg long] 0] [lindex $args $idx]
                incr idx
            }
        }
    }

    return [concat $rc [lrange $args $idx end]]

}

proc parse_args { args } {

    set options [dict create]

    for { set i 0 } { $i < [llength $args] } { incr i } {

        unset -nocomplain value

        set word [lindex $args $i]

        switch -glob $word {
            --*=* {
                set word [split $word "="]
                set value [join [lrange $word 1 end] "="]
                set word [lindex $word 0]
                set arg [get_arg $word]
            }
            --* {
                set arg [get_arg $word]
            }
            -* {
                set long_opts [list]
                for { set j 1 } { $j < [string length $word] } { incr j } {
                    set arg [get_arg [string index $word $j]]
                    lappend long_opts [lindex [dict get $arg long] 0]
                    if { [dict get $arg type] ne "option" } {
                        continue
                    }
                    incr j
                    if { $j < [string length $word] } {
                        lappend long_opts [string range $word $j end]
                    }
                    break
                }
                set args [lreplace $args $i $i {*}$long_opts]
                incr i -1
                continue
            }
            default {
                break
            }
        }

        set name [string range [lindex [dict get $arg long] 0] 2 end]

        switch -exact [dict get $arg type] {
            "operation" {
                if { [dict exists $options operation] } {
                    invalid_operation
                }
                dict set options operation $name
            }
            "switch" {
                dict set options $name 1
            }
            "option" {
                if { ![info exists value] } {
                    incr i
                    if { $i >= [llength $args] } {
                        invalid_no_argument $word
                    }
                    set value [lindex $args $i]
                }
                dict set options $name $value
            }
        }

    }

    if { ![dict exists $options operation] } {
        invalid_usage
    }

    dict set options - [lrange $args $i end]

    return $options

}
