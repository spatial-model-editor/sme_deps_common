# libsbml-static [![Build Status](https://travis-ci.org/lkeegan/libsbml-static.svg?branch=master)](https://travis-ci.org/lkeegan/libsbml-static)
This repo provides a static version of the [libSBML](http://sbml.org/SBML_Projects/libSBML) library, taken from the **experimental** branch of the svn repo, compiled with the [spatial extension](https://sourceforge.net/p/sbml/code/HEAD/tree/trunk/specifications/sbml-level-3/version-1/spatial/specification/spatial-v1-sbml-l3v1-rel0.93.pdf?format=raw) enabled and using the [libexpat](https://libexpat.github.io/) XML library.

Get the latest versions here:

  - linux: [libsbml-static-linux.tgz](https://github.com/lkeegan/libsbml-static/releases/latest/download/libsbml-static-linux.tgz)
  - osx: [libsbml-static-osx.tgz](https://github.com/lkeegan/libsbml-static/releases/latest/download/libsbml-static-osx.tgz)

This tarball contains the include headers `include/sbml`, the libSBML static library `lib/libsbml-static.a`, and the libexpat static library `lib/libexpat.a` which libSBML depends on.

## Updating this repo
Any tagged commit will trigger linux & osx travis builds that will check out and compile static versions of libSBML and libexpat, create a tarball containing the resulting `lib/libsbml-static.a`, `lib/libexpat.a` and `include/sbml`, and add this file to the release associated to the tagged commit on github.

To make a new release, first update the libSBML svn revision number in [.travis.yml](https://github.com/lkeegan/libsbml-static/blob/master/.travis.yml#L3) and commit the changes:
```
git commit -am "revision update"
git push
```
then tag this commit and push the tag to github:
```
git tag <tagname>
git push origin <tagname>
```
The tagged commit will result in a github release with name <tagname>, and also triggers linux & osx travis builds which compile the library and add a tarball of the result to the release.

To see the last 5 revisions in the experimental branch of the libSBML svn repo:
```
 svn log -l 5 https://svn.code.sf.net/p/sbml/code/branches/libsbml-experimental
```
