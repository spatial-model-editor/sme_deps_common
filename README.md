# libsbml-static-linux [![Build Status](https://travis-ci.org/lkeegan/libsbml-static-linux.svg?branch=master)](https://travis-ci.org/lkeegan/libsbml-static-linux)
This repo provides a static C/C++ linux version of the [libSBML](http://sbml.org/SBML_Projects/libSBML) library, taken from the **experimental** branch of the svn repo, and compiled with the **spatial** extension enabled.

Get the latest version here: [libsbml-static.tgz](https://github.com/lkeegan/libsbml-static-linux/releases/latest/download/libsbml-static.tgz)

## Updating this repo
Any tagged commit will trigger a travis build that will check out, compile and locally install libSBML, then create a tarball containing the resulting `lib/libsbml-static.a` and `include/sbml`, and add this file to the release associated to the tagged commit on github.

To make a new release, first update the svn revision number being checked out out in [.travis.yml](https://github.com/lkeegan/libsbml-static-linux/blob/master/.travis.yml#L7) to the desired revision number in the experimental branch of the libSBML svn repo, and commit the changes:

```
git commit -am "revision update"
git push
```

Then tag this commit and push the tag to github:
```
git tag <tagname>
git push origin <tagname>
```

To see the last 5 revisions in the svn repo:
```
 svn log -l 5 https://svn.code.sf.net/p/sbml/code/branches/libsbml-experimental
```
