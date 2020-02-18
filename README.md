# libsbml-static [![Build Status](https://travis-ci.org/lkeegan/libsbml-static.svg?branch=master)](https://travis-ci.org/lkeegan/libsbml-static) [![Build status](https://ci.appveyor.com/api/projects/status/tuw34pchfl4h37uf?svg=true)](https://ci.appveyor.com/project/lkeegan/libsbml-static)

This repo provides the following statically compiled libraries:

  - [libSBML](http://sbml.org/SBML_Projects/libSBML)
    - taken from the **experimental** branch of the svn repo
    - compiled with the [spatial extension](https://sourceforge.net/p/sbml/code/HEAD/tree/trunk/specifications/sbml-level-3/version-1/spatial/specification/spatial-v1-sbml-l3v1-rel0.93.pdf?format=raw) enabled
  - [symengine](https://github.com/symengine/symengine)
    - compiled with LLVM enabled, using static libraries from https://github.com/lkeegan/llvm-static
  - [libexpat](https://libexpat.github.io/)
  - [gmp](https://gmplib.org)
  - [spdlog](https://github.com/gabime/spdlog)
  - [muparser](https://github.com/beltoforion/muparser)
  - [libTIFF](http://www.libtiff.org/)
  - [fmt](https://fmt.dev/)
  - [tbb](https://github.com/intel/tbb)

Get the latest versions here:

  - linux: [libsbml-static-linux.tgz](https://github.com/lkeegan/libsbml-static/releases/latest/download/libsbml-static-linux.tgz)
  - osx: [libsbml-static-osx.tgz](https://github.com/lkeegan/libsbml-static/releases/latest/download/libsbml-static-osx.tgz)
  - windows: [libsbml-static-windows.zip](https://github.com/lkeegan/libsbml-static/releases/latest/download/libsbml-static-windows.zip)

## Updating this repo
Any tagged commit will result in a github release.

To make a new release, first update the version numbers in [build.sh](https://github.com/lkeegan/libsbml-static/blob/master/build.sh#L5), then commit the changes:
```
git commit -am "revision update"
git push
```
This will trigger the linux & osx [travis builds](https://travis-ci.org/lkeegan/libsbml-static) and a windows [appveyor build](https://ci.appveyor.com/project/lkeegan/libsbml-static), which will download and compile the libraries. If the builds are sucessful, tag this commit and push the tag to github:
```
git tag <tagname>
git push origin <tagname>
```
The tagged commit will trigger the builds again, but this time they will each add an archive of the resulting static libraries to the `<tagname>` release on this github repo.

To see the last 5 revisions in the experimental branch of the libSBML svn repo:
```
 svn log -l 5 https://svn.code.sf.net/p/sbml/code/branches/libsbml-experimental
```
