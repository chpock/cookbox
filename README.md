# cookbox

An archiver that allows to use various compression methods to package files. This is an example of working with Tcl extension [cookfs](https://github.com/chpock/cookfs).

## Description

The following examples are demonstrated here:

* how to create a cookfs archive with Tcl runtime libraries/scripts and application scripts during the build process
* how to use cookfs and build a single executable with Tcl interpreter, Tcl runtime scripts, application scripts
* how to use cookfs from Tcl scripts to store data

This is not a full-fledged archiver or utility. There are no optimizations, no error checking, no functional testing. The goal of this application is to show an example of using cookfs using a minimum amount of code for clarity, but also to provide a minimum amount of usability.

## How to use

Working with the utility is similar to working with GNU tar. All GNU tar options are accepted, although most are ignored.

The options and modes that are supported are listed when `cookbox --help` is executed:

```
$ ./cookbox --help
Usage: cookbox [OPTION...] [FILE]...
cookbox saves many files together into a single disk archive, and can restore individual files from the archive.

Examples:
  cookbox -cf archive.cookfs foo bar  # Create archive.cookfs from files foo and bar.
  cookbox -tvf archive.cookfs         # List all files in archive.cookfs verbosely.
  cookbox -xf archive.cookfs          # Extract all files from archive.cookfs.

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
```

The modes of creating, unpacking, and checking archives work completely similar to the mode of the GNU tar command.

Since this is a demotracking program, some demotracking modes are available, which need to be described specifically.

### Run interactive Tcl shell (-shell)

tclsh with [TclReadLine](https://github.com/suewonjp/tclsh-wrapper/tree/master) is bundled and can be run interactively. For example:

```
$ ./cookbox --shell
> set tcl_patchLevel
9.0b3
> puts "Hello world!"
Hello world!

> exit
```

### Evaluate the provided script or file (--eval)

Using this option it is possible to execute a Tcl script from the command line or a file. For example:

```
$ ./cookbox --eval 'puts "Hello world!"'
Hello world!
```

or:

```
$ cat script.tcl
puts "Hello World!"
$ ./cookbox --eval -f script.tcl
Hello World!

```

### Wrap files to an executable (--cookinize)

Using this option, it is possible to make an executable file from a Tcl script. Use the file name `main.tcl` as it is this file in the archive that runs automatically at startup. For example:

```
$ cat main.tcl
puts "Hello World!"
$ ./cookbox --cookinize -f myapplication main.tcl
$ ./myapplication
Hello World!
```

### Analyze an archive (--analyze)

Using this option it is possible to check the content of an archive. For example, in this case cookbox will show its own content:

```
$ ./cookbox --analyze -f cookbox
Total pages: 27

Stub    : packed:  3184983

Page  0 : packed:     8854; unpacked:    40415; ratio: 21.91%; number of files: 1
Page  1 : packed:    42306; unpacked:   180756; ratio: 23.41%; number of files: 1
Page  2 : packed:    10337; unpacked:    37407; ratio: 27.63%; number of files: 1
Page  3 : packed:    25831; unpacked:   104660; ratio: 24.68%; number of files: 1
Page  4 : packed:    15267; unpacked:    59952; ratio: 25.47%; number of files: 1
Page  5 : packed:    70835; unpacked:    70835; ratio: 100.00%; number of files: 1
Page  6 : packed:    22826; unpacked:    92873; ratio: 24.58%; number of files: 1
Page  7 : packed:    16172; unpacked:    97050; ratio: 16.66%; number of files: 1
Page  8 : packed:    14788; unpacked:    48207; ratio: 30.68%; number of files: 1
Page  9 : packed:    29805; unpacked:   132509; ratio: 22.49%; number of files: 1
Page 10 : packed:    24523; unpacked:   130423; ratio: 18.80%; number of files: 1
Page 11 : packed:    22631; unpacked:    91831; ratio: 24.64%; number of files: 1
Page 12 : packed:    14439; unpacked:    85574; ratio: 16.87%; number of files: 1
Page 13 : packed:    13358; unpacked:    82537; ratio: 16.18%; number of files: 1
Page 14 : packed:    15096; unpacked:    93918; ratio: 16.07%; number of files: 1
Page 15 : packed:    15082; unpacked:    86619; ratio: 17.41%; number of files: 1
Page 16 : packed:    14324; unpacked:    84532; ratio: 16.95%; number of files: 1
Page 17 : packed:    14498; unpacked:    85574; ratio: 16.94%; number of files: 1
Page 18 : packed:    13120; unpacked:    80453; ratio: 16.31%; number of files: 1
Page 19 : packed:     8018; unpacked:    70974; ratio: 11.30%; number of files: 1
Page 20 : packed:    15008; unpacked:    92877; ratio: 16.16%; number of files: 1
Page 21 : packed:    14126; unpacked:    48028; ratio: 29.41%; number of files: 1
Page 22 : packed:    13576; unpacked:    41862; ratio: 32.43%; number of files: 1
Page 23 : packed:    13627; unpacked:    46996; ratio: 29.00%; number of files: 1
Page 24 : packed:    53502; unpacked:   255998; ratio: 20.90%; number of files: 87
Page 25 : packed:     5949; unpacked:    19687; ratio: 30.22%; number of files: 3
Page 26 : packed:     4959; unpacked:    23629; ratio: 20.99%; number of files: 2

Index   : packed:        -; unpacked:     4615; ratio: -

-----------------------------------------------------------------------

Content:

Page  0 : lib/TclReadLine/TclReadLine.tcl
Page  1 : lib/tcl9/9.0/http-2.10b3.tm
Page  2 : lib/tcl9/9.0/msgcat-1.7.1.tm
Page  3 : lib/tcl9/9.0/tcltest-2.5.8.tm
Page  4 : lib/tcl9.0/clock.tcl
Page  5 : lib/tcl9.0/cookiejar0.2/public_suffix_list.dat.gz
Page  6 : lib/tcl9.0/encoding/big5.enc
Page  7 : lib/tcl9.0/encoding/cns11643.enc
Page  8 : lib/tcl9.0/encoding/cp932.enc
Page  9 : lib/tcl9.0/encoding/cp936.enc
Page 10 : lib/tcl9.0/encoding/cp949.enc
Page 11 : lib/tcl9.0/encoding/cp950.enc
Page 12 : lib/tcl9.0/encoding/euc-cn.enc
Page 13 : lib/tcl9.0/encoding/euc-jp.enc
Page 14 : lib/tcl9.0/encoding/euc-kr.enc
Page 15 : lib/tcl9.0/encoding/gb12345.enc
Page 16 : lib/tcl9.0/encoding/gb2312-raw.enc
Page 17 : lib/tcl9.0/encoding/gb2312.enc
Page 18 : lib/tcl9.0/encoding/jis0208.enc
Page 19 : lib/tcl9.0/encoding/jis0212.enc
Page 20 : lib/tcl9.0/encoding/ksc5601.enc
Page 21 : lib/tcl9.0/encoding/macJapan.enc
Page 22 : lib/tcl9.0/encoding/shiftjis.enc
Page 23 : lib/tcl9.0/safe.tcl
Page 24 : lib/TclReadLine/pkgIndex.tcl lib/cookbox1.0.0/cookbox.tcl lib/cookbox1.0.0/pkgIndex.tcl lib/tcl9.0/auto.tcl lib/tcl9.0/foreachline.tcl lib/tcl9.0/history.tcl lib/tcl9.0/icu.tcl lib/tcl9.0/init.tcl lib/tcl9.0/install.tcl lib/tcl9.0/package.tcl lib/tcl9.0/parray.tcl lib/tcl9.0/readfile.tcl lib/tcl9.0/tclAppInit.c lib/tcl9.0/tclIndex lib/tcl9.0/tm.tcl lib/tcl9.0/word.tcl lib/tcl9.0/writefile.tcl lib/tcl9.0/cookiejar0.2/cookiejar.tcl lib/tcl9.0/cookiejar0.2/idna.tcl lib/tcl9.0/cookiejar0.2/pkgIndex.tcl lib/tcl9.0/encoding/ascii.enc lib/tcl9.0/encoding/cp1250.enc lib/tcl9.0/encoding/cp1251.enc lib/tcl9.0/encoding/cp1252.enc lib/tcl9.0/encoding/cp1253.enc lib/tcl9.0/encoding/cp1254.enc lib/tcl9.0/encoding/cp1255.enc lib/tcl9.0/encoding/cp1256.enc lib/tcl9.0/encoding/cp1257.enc lib/tcl9.0/encoding/cp1258.enc lib/tcl9.0/encoding/cp437.enc lib/tcl9.0/encoding/cp737.enc lib/tcl9.0/encoding/cp775.enc lib/tcl9.0/encoding/cp850.enc lib/tcl9.0/encoding/cp852.enc lib/tcl9.0/encoding/cp855.enc lib/tcl9.0/encoding/cp857.enc lib/tcl9.0/encoding/cp860.enc lib/tcl9.0/encoding/cp861.enc lib/tcl9.0/encoding/cp862.enc lib/tcl9.0/encoding/cp863.enc lib/tcl9.0/encoding/cp864.enc lib/tcl9.0/encoding/cp865.enc lib/tcl9.0/encoding/cp866.enc lib/tcl9.0/encoding/cp869.enc lib/tcl9.0/encoding/cp874.enc lib/tcl9.0/encoding/dingbats.enc lib/tcl9.0/encoding/ebcdic.enc lib/tcl9.0/encoding/gb1988.enc lib/tcl9.0/encoding/iso2022-jp.enc lib/tcl9.0/encoding/iso2022-kr.enc lib/tcl9.0/encoding/iso2022.enc lib/tcl9.0/encoding/iso8859-1.enc lib/tcl9.0/encoding/iso8859-10.enc lib/tcl9.0/encoding/iso8859-11.enc lib/tcl9.0/encoding/iso8859-13.enc lib/tcl9.0/encoding/iso8859-14.enc lib/tcl9.0/encoding/iso8859-15.enc lib/tcl9.0/encoding/iso8859-16.enc lib/tcl9.0/encoding/iso8859-2.enc lib/tcl9.0/encoding/iso8859-3.enc lib/tcl9.0/encoding/iso8859-4.enc lib/tcl9.0/encoding/iso8859-5.enc lib/tcl9.0/encoding/iso8859-6.enc lib/tcl9.0/encoding/iso8859-7.enc lib/tcl9.0/encoding/iso8859-8.enc lib/tcl9.0/encoding/iso8859-9.enc lib/tcl9.0/encoding/jis0201.enc lib/tcl9.0/encoding/koi8-r.enc lib/tcl9.0/encoding/koi8-ru.enc lib/tcl9.0/encoding/koi8-t.enc lib/tcl9.0/encoding/koi8-u.enc lib/tcl9.0/encoding/macCentEuro.enc lib/tcl9.0/encoding/macCroatian.enc lib/tcl9.0/encoding/macCyrillic.enc lib/tcl9.0/encoding/macDingbats.enc lib/tcl9.0/encoding/macGreek.enc lib/tcl9.0/encoding/macIceland.enc lib/tcl9.0/encoding/macRoman.enc lib/tcl9.0/encoding/macRomania.enc lib/tcl9.0/encoding/macThai.enc lib/tcl9.0/encoding/macTurkish.enc lib/tcl9.0/encoding/macUkraine.enc lib/tcl9.0/encoding/symbol.enc lib/tcl9.0/encoding/tis-620.enc lib/tcl9.0/opt0.4/optparse.tcl lib/tcl9.0/opt0.4/pkgIndex.tcl
Page 25 : lib/TclReadLine/help.txt lib/tcl9/9.0/platform-1.0.19.tm lib/tcl9/9.0/platform/shell-1.1.4.tm
Page 26 : args.tcl main.tcl
```

## How to build

Everything needed for the build is in this repository. This package uses the Tcl Extension Architecture (TEA) to build on Linux, Mac, or Windows platforms. For Windows platform only building with Mingw-w64 toolchain is supported.

Here are the simple build commands:

```
$ git clone https://github.com/chpock/cookbox.git
$ cd cookbox
$ git submodule update --init --recursive
$ mkdir build && cd build
$ ../build.sh

```

It is possible to build `cookbox` with Tcl 8.6.14 or Tcl 9.0b3. The default will be Tcl 8.6.14. To use Tcl 9.0b3, the appropriate parameter for `build.sh` must be specified:

```
$ ../build.sh 9.0
```

## Binaries

Already built binaries are available on Github under [Releases](https://github.com/chpock/cookbox/releases).

There are binaries build with Tcl 8.6.14 or Tcl 9.0b3 for the following platforms:

- **Windows x86** and **x86\_64**: Windows 7 or higher is required. However, they are only tested on Windows 10.
- **Linux x86** and **x86\_64**: built and tested on Cenos6.10. Require glibc v2.12 or higher.
- **MacOS x86** and **x86\_64**: built and tested on MacOS 10.12. However, these packages should be compatible with MacOS as of version 10.6.

## Copyrights

Copyright (c) 2024 Konstantin Kushnir <chpock@gmail.com>

## License

`cookbox` sources are available under the same license as [Tcl core](https://tcl.tk/software/tcltk/license.html).
