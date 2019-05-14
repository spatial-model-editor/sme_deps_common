# libsbml-static-linux [![Build Status](https://travis-ci.org/lkeegan/libsbml-static-linux.svg?branch=master)](https://travis-ci.org/lkeegan/libsbml-static-linux)
This repo provides a static C/C++ linux version of the [libSBML](http://sbml.org/SBML_Projects/libSBML) library, taken from the **experimental** branch of the svn repo, compiled with the **spatial** extension enabled and using the [libexpat](https://libexpat.github.io/) XML library.

Get the latest version here: [libsbml-static-linux.tgz](https://github.com/lkeegan/libsbml-static-linux/releases/latest/download/libsbml-static-linux.tgz)

This tarball contains the include headers `include/sbml`, the libSBML static library `lib/libsbml-static.a`, and the libexpat static library `lib/libexpat.a`.

## Updating this repo
Any tagged commit will trigger a travis build that will check out, compile and locally install libSBML. It also compiles a static version of the libexpat XML library. It then creates a tarball containing the resulting `lib/libsbml-static.a`, `lib/libexpat.a` and `include/sbml`, and adds this file to the release associated to the tagged commit on github.

The latest release is always available from
```
https://github.com/lkeegan/libsbml-static-linux/releases/latest/download/libsbml-static-linux.tgz
```

To make a new release, first update the svn revision number being checked out out in [.travis.yml](https://github.com/lkeegan/libsbml-static-linux/blob/master/.travis.yml#L19) to the desired revision number in the experimental branch of the libSBML svn repo, and commit the changes:

```
git commit -am "revision update"
git push
```

Then tag this commit and push the tag to github:
```
git tag <tagname>
git push origin <tagname>
```
The tagged commit will then trigger the travis build.

To see the last 5 revisions in the svn repo:
```
 svn log -l 5 https://svn.code.sf.net/p/sbml/code/branches/libsbml-experimental
```
