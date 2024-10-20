# cookbox.tcl - just sample package
#
# Copyright (c) 2024 Konstantin Kushnir <chpock@gmail.com>
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

proc recursive_glob { dir pattern } {
    set files [lsort [glob -nocomplain -type f -directory $dir $pattern]]
    foreach dir [lsort [glob -nocomplain -type d -directory $dir *]] {
        lappend files {*}[recursive_glob $dir $pattern]
    }
    return $files
}

proc op-analyze { options } {

    if { ![dict exists $options file] } {
        show_usage "Refusing to read archive contents from terminal (missing -f option?)"
    }

    set archive [dict get $options file]

    if { ![file isfile $archive] } {
        show_error "$archive: File does not exist"
    }

    set fsid [cookfs::Mount $archive $archive -readonly {*}[dict get $options cookfs_opts]]

    set root $archive

    set frmsize [list apply { { size } {
        return [format "%8d" $size]
    } }]

    set frmratio [list apply { { usize csize } {
        return [format "%.2f%%" [expr { 100.0 * $csize / $usize }]]
    } }]

    array set pindex [list]

    foreach fn [recursive_glob $root *] {
        foreach block [file attributes $fn -blocks] {
            lappend pindex([dict get $block page]) [file attributes $fn -relative]
        }
    }

    set length [file attribute $root -pages]

    puts "Total pages: $length"
    puts ""

    set size [dict get [file attributes $root -parts] headsize]

    puts "Stub    : packed: [{*}$frmsize $size]"
    puts ""

    for { set i 0 } { $i < $length } { incr i } {

        set page [file attributes $root -pages $i]
        set csize [dict get $page compsize]
        set usize [dict get $page uncompsize]
        set comp  [dict get $page compression]

        if { [info exists pindex($i)] } {
            set nfiles [llength $pindex($i)]
        } {
            set nfiles "<bootstrap>"
        }
        puts "Page [format "%2d" $i] : packed($comp): [{*}$frmsize $csize]; unpacked: [{*}$frmsize $usize]; ratio: [{*}$frmratio $usize $csize]; number of files: $nfiles"
    }

    puts ""

    set page [file attributes $root -pages pgindex]
    set csize [dict get $page compsize]
    set usize [dict get $page uncompsize]
    set comp  [dict get $page compression]
    puts "PgIndex : packed($comp): [{*}$frmsize $csize]; unpacked: [{*}$frmsize $usize]; ratio: [{*}$frmratio $usize $csize]"

    set page [file attributes $root -pages fsindex]
    set csize [dict get $page compsize]
    set usize [dict get $page uncompsize]
    set comp  [dict get $page compression]
    puts "FsIndex : packed($comp): [{*}$frmsize $csize]; unpacked: [{*}$frmsize $usize]; ratio: [{*}$frmratio $usize $csize]"

    puts ""
    puts "-----------------------------------------------------------------------"
    puts ""
    puts "Content:"
    puts ""

    for { set i 0 } { $i < $length } { incr i } {
        if { ![info exists pindex($i)] } continue
        puts "Page [format "%2d" $i] : $pindex($i)"
    }

    cookfs::Unmount $archive

}

package provide cookbox 1.1.0