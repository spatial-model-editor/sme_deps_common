# libsbml-static-linux [![Build Status](https://travis-ci.org/lkeegan/libsbml-static-linux.svg?branch=master)](https://travis-ci.org/lkeegan/libsbml-static-linux)
This repo provides a static linux version of the [libSBML](http://sbml.org/SBML_Projects/libSBML) library, taken from the **experimental** branch of the svn repo, and compiled with the **spatial** extension enabled.

The latest version of the static library and the include directory are available here:
```
https://github.com/lkeegan/libsbml-static-linux/releases/download/26045-tgz/libsbml-static.tgz
```

## Updating this repo
Any tagged commit will trigger a travis build that will check out and compile libSBML and add the resulting `libsbml-static.a` file to the release `<tagname>`, which is then available for download at:

To make a new release, first update the svn revision number being checked out out in [.travis.yml](https://github.com/lkeegan/libsbml-static-linux/blob/c743a2b318f7c5be74c616e59cdc3fa206c768de/.travis.yml#L7) to the desired revision number in the experimental branch of the libSBML svn repo, and commit the changes:

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
