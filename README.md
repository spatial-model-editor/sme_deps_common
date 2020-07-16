# libsbml-static [![Build Status](https://travis-ci.org/lkeegan/libsbml-static.svg?branch=master)](https://travis-ci.org/lkeegan/libsbml-static)

This repo provides the following statically compiled libraries:

  - [libSBML](https://github.com/sbmlteam/libsbml)
    - development branch compiled with the [spatial extension](https://sourceforge.net/p/sbml/code/HEAD/tree/trunk/specifications/sbml-level-3/version-1/spatial/specification/spatial-v1-sbml-l3v1-rel0.95.pdf?format=raw) enabled
  - [symengine](https://github.com/symengine/symengine)
    - compiled with LLVM enabled, using static libraries from <https://github.com/lkeegan/llvm-static>
  - [libexpat](https://libexpat.github.io/)
  - [gmp](https://gmplib.org)
  - [spdlog](https://github.com/gabime/spdlog)
  - [muparser](https://github.com/beltoforion/muparser)
  - [libTIFF](http://www.libtiff.org/)
  - [fmt](https://fmt.dev/)
  - [tbb](https://github.com/intel/tbb)

Get the latest versions here:

  - linux (gcc 9 / Ubuntu 16.04): [libsbml-static-linux.tgz](https://github.com/lkeegan/libsbml-static/releases/latest/download/libsbml-static-linux.tgz)
  - osx (Apple clang 11 / macOS 10.14): [libsbml-static-osx.tgz](https://github.com/lkeegan/libsbml-static/releases/latest/download/libsbml-static-osx.tgz)
  - win32 (mingw-w64-i686-gcc 10): [libsbml-static-win32.tgz](https://github.com/lkeegan/libsbml-static/releases/latest/download/libsbml-static-win32.tgz)
  - win64 (mingw-w64-x86_64-gcc 10): [libsbml-static-win64.tgz](https://github.com/lkeegan/libsbml-static/releases/latest/download/libsbml-static-win64.tgz)

## Updating this repo
Any tagged commit will result in a github release.

To make a new release, first update the version numbers in [build.sh](https://github.com/lkeegan/libsbml-static/blob/master/build.sh#L7), then commit the changes:
```
git commit -am "revision update"
git push
```
This will trigger the [travis builds](https://travis-ci.org/lkeegan/libsbml-static) which will compile the libraries. If the builds are sucessful, tag this commit and push the tag to github:
```
git tag <tagname>
git push origin <tagname>
```
The tagged commit will trigger the builds again, but this time they will each add an archive of the resulting static libraries to the `<tagname>` release on this github repo.
