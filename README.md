# sme_deps_common [![Release Builds](https://github.com/spatial-model-editor/sme_deps_common/workflows/Release%20Builds/badge.svg)](https://github.com/spatial-model-editor/sme_deps_common/actions?query=workflow)

This repo provides the following statically compiled libraries:

- [libSBML](https://github.com/sbmlteam/libsbml)
  - compiled with the [spatial extension](https://github.com/sbmlteam/sbml-specifications/blob/release/sbml-level-3/version-1/spatial/specification/sbml.level-3.version-1.spatial.version-1.release-1.pdf) enabled
- [symengine](https://github.com/symengine/symengine)
  - compiled with LLVM enabled
- [libexpat](https://libexpat.github.io/)
- [GMP](https://gmplib.org)
- [MPFR](https://www.mpfr.org)
- [spdlog](https://github.com/gabime/spdlog)
- [libTIFF](http://www.libtiff.org/)
- [fmt](https://fmt.dev/)
- [oneTBB](https://github.com/oneapi-src/oneTBB)
- [oneDPL](https://github.com/oneapi-src/oneDPL)
- [opencv](https://github.com/opencv/opencv)
- [catch2](https://github.com/catchorg/Catch2)
- [benchmark](https://github.com/google/benchmark)
- [CGAL](https://github.com/CGAL/cgal)
- [Boost](https://www.boost.org/)
- [QCustomPlot](https://www.qcustomplot.com)
- [Cereal](https://github.com/USCiLab/cereal)
- [bzip2](https://www.sourceware.org/bzip2/)
- [pagmo](https://github.com/esa/pagmo2)
- [zipper](https://github.com/fbergmann/zipper)
- [libCombine](https://github.com/sbmlteam/libCombine)
- [function2](https://github.com/Naios/function2)
- [VTK](https://gitlab.kitware.com/vtk/vtk)
- [LLVM](https://llvm.org/) (copied from <https://github.com/spatial-model-editor/sme_deps_llvm>)
- [Qt](https://doc.qt.io/) (copied from <https://github.com/spatial-model-editor/sme_deps_qt>)

Get the latest versions here:

- linux (clang 17 / Ubuntu 20.04): [sme_deps_common_linux.tgz](https://github.com/spatial-model-editor/sme_deps_common/releases/latest/download/sme_deps_common_linux.tgz)
- osx (Xcode 14.3 / macOS 13): [sme_deps_common_osx.tgz](https://github.com/spatial-model-editor/sme_deps_common/releases/latest/download/sme_deps_common_osx.tgz)
- win64-mingw (mingw-w64-x86_64-gcc 13): [sme_deps_common_win64-mingw.tgz](https://github.com/spatial-model-editor/sme_deps_common/releases/latest/download/sme_deps_common_win64-mingw.tgz)

## Updating this repo

Any tagged commit will result in a github release.

To make a new release, update the library version numbers in [release.yml](https://github.com/spatial-model-editor/sme_deps_common/blob/main/.github/workflows/release.yml#L6) (and the build script [build.sh](https://github.com/spatial-model-editor/sme_deps_common/blob/main/build.sh) if necessary), then commit the changes:

```
git commit -am "revision update"
git push
```

This will trigger GitHub Action builds which will compile the libraries. If the builds are sucessful, tag this commit with the date and push the tag to github:

```
git tag YYYY.MM.DD
git push origin YYYY.MM.DD
```

The tagged commit will trigger the builds again, but this time they will each add an archive of the resulting static libraries to the `YYYY.MM.DD` release on this github repo.
