# bootstrap.tcl - creates cookfs bootstrap archive
#
# Copyright (c) 2024 Konstantin Kushnir <chpock@gmail.com>
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

package require cookfs

# Output archive file name
set archive [lindex $argv 0]
puts "** output archive: $archive"

# Directory with base Tcl runtime files
set runtime [lindex $argv 1]
puts "** Tcl runtime directory: $runtime"

# Additional files/directories that will be copied to cookfs root
set scripts [lrange $argv 2 end]
puts "** Custom files: $scripts"

puts ""

# Let's add base Tcl runtime files using zstd compression for faster access.
# We will use a compression level of 19. However, the maximum level is 22.
if { [catch {

    set fsid [cookfs::Mount $archive $archive -compression zstd:19]
    #set fsid [cookfs::Mount $archive $archive -compression lzma:9]

    # Copy Tcl runtime to the archive
    foreach file [glob -directory $runtime *] {
        puts "Add Tcl runtime file/directory: $file"
        file copy $file $archive
    }

    # Now let's use more efficient compression for everything else
    $fsid compression "lzma:9"

    foreach file $scripts {
        puts "Add custom file/directory: $file"
        file copy $file $archive
    }

    # We are done. Unmount and save.
    cookfs::Unmount $archive
    puts "Done."

} err] } {
    puts stderr "Error while creating the archive: $err"
    exit 1
}