# sme_deps_common [![Release Builds](https://github.com/spatial-model-editor/sme_deps_common/workflows/Release%20Builds/badge.svg)](https://github.com/spatial-model-editor/sme_deps_common/actions?query=workflow)

This repo provides the following statically compiled libraries:

- [libSBML](https://github.com/sbmlteam/libsbml)
  - compiled with the [spatial extension](https://sourceforge.net/p/sbml/code/HEAD/tree/trunk/specifications/sbml-level-3/version-1/spatial/specification/spatial-v1-sbml-l3v1-rel0.95.pdf?format=raw) enabled
- [symengine](https://github.com/symengine/symengine)
  - compiled with LLVM enabled
- [libexpat](https://libexpat.github.io/)
- [GMP](https://gmplib.org)
- [MPFR](https://www.mpfr.org)
- [spdlog](https://github.com/gabime/spdlog)
- [muparser](https://github.com/beltoforion/muparser)
- [libTIFF](http://www.libtiff.org/)
- [fmt](https://fmt.dev/)
- [tbb](https://github.com/intel/tbb)
- [opencv](https://github.com/opencv/opencv)
- [catch2](https://github.com/catchorg/Catch2)
- [benchmark](https://github.com/google/benchmark)
- [CGAL](https://github.com/CGAL/cgal)
- [Boost](https://www.boost.org/)
- [QCustomPlot](https://www.qcustomplot.com)
- [Cereal](https://github.com/USCiLab/cereal)
- [zlib](https://zlib.net/)
- [pagmo](https://github.com/esa/pagmo2)
- [LLVM](https://llvm.org/) (copied from <https://github.com/spatial-model-editor/sme_deps_llvm>)
- [Qt](https://doc.qt.io/) (copied from <https://github.com/spatial-model-editor/sme_deps_qt>)

Get the latest versions here:

- linux (clang 13 / Ubuntu 18.04): [sme_deps_common_linux.tgz](https://github.com/spatial-model-editor/sme_deps_common/releases/latest/download/sme_deps_common_linux.tgz)
- osx (Apple clang 12 / macOS 10.15): [sme_deps_common_osx.tgz](https://github.com/spatial-model-editor/sme_deps_common/releases/latest/download/sme_deps_common_osx.tgz)
- win32-mingw (mingw-w64-i686-gcc 11): [sme_deps_common_win32-mingw.tgz](https://github.com/spatial-model-editor/sme_deps_common/releases/latest/download/sme_deps_common_win32-mingw.tgz)
- win64-mingw (mingw-w64-x86_64-gcc 11): [sme_deps_common_win64-mingw.tgz](https://github.com/spatial-model-editor/sme_deps_common/releases/latest/download/sme_deps_common_win64-mingw.tgz)
- win32-msvc (VC++ 2015 Toolset): [sme_deps_common_win32-msvc.tgz](https://github.com/spatial-model-editor/sme_deps_common/releases/latest/download/sme_deps_common_win32-msvc.tgz)
- win64-msvc (VC++ 2015 Toolset): [sme_deps_common_win64-msvc.tgz](https://github.com/spatial-model-editor/sme_deps_common/releases/latest/download/sme_deps_common_win64-msvc.tgz)

## Updating this repo

Any tagged commit will result in a github release.

To make a new release, update the library version numbers in [release.yml](https://github.com/spatial-model-editor/sme_deps_common/blob/master/.github/workflows/release.yml#L6) (and the build script [build.sh](https://github.com/spatial-model-editor/sme_deps_common/blob/master/build.sh) if necessary), then commit the changes:

```
git commit -am "revision update"
git push
```

This will trigger GitHub Action builds which will compile the libraries. If the builds are sucessful, tag this commit and push the tag to github:

```
git tag <tagname>
git push origin <tagname>
```

The tagged commit will trigger the builds again, but this time they will each add an archive of the resulting static libraries to the `<tagname>` release on this github repo.
