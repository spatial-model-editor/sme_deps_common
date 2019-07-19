#!/bin/bash
BUILD_DIR=${1:-"C:"}
N=${2:-2}

LIBSBML_REVISION="26089"
LIBEXPAT_VERSION="R_2_2_7"
SYMENGINE_VERSION="v0.4.0"
GMP_VERSION="6.1.2"

# make sure we get the right mingw64 version of g++ on appveyor
PATH=/mingw64/bin:$PATH

echo "LIBSBML_REVISION: ${LIBSBML_REVISION}"
echo "LIBEXPAT_VERSION: ${LIBEXPAT_VERSION}"
echo "SYMENGINE_VERSION: ${SYMENGINE_VERSION}"
echo "GMP_VERSION: ${GMP_VERSION}"
echo "N_PROCS: ${N_PROCS}"
echo "PATH: ${PATH}"
g++ --version
make --version

mkdir $BUILD_DIR/tarball

# build static version of gmp
# todo: investigate host=amd64 config options
# currently using --disable-assembly which should work but slow

wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.bz2
tar xjf "gmp-${GMP_VERSION}.tar.bz2"
cd gmp-${GMP_VERSION}
./configure --prefix=$BUILD_DIR/tarball/gmp --disable-shared --enable-static --disable-assembly --with-pic
make -j$N
make check
make install
cd ..

# build static version of symengine
git clone -b $SYMENGINE_VERSION --depth 1 https://github.com/symengine/symengine.git
cd symengine
mkdir build
cd build
cmake --help
cmake -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/tarball/symengine -DGMP_INCLUDE_DIR=$BUILD_DIR/tarball/gmp/include -DGMP_LIBRARY=$BUILD_DIR/tarball/gmp/lib/libgmp.a -G "Unix Makefiles" ..
make -j$N
make test
make install
cd ../../

# build static version of expat xml library
git clone https://github.com/libexpat/libexpat.git
cd libexpat
git checkout $LIBEXPAT_VERSION
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS} -fpic" -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fpic" -DBUILD_doc=OFF -DBUILD_examples=OFF -DBUILD_shared=off -DBUILD_tests=OFF -DBUILD_tools=OFF -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/expat ../expat
make -j$N
make install
cd ../../

# build static version of libSBML including spatial extension
svn -q co https://svn.code.sf.net/p/sbml/code/branches/libsbml-experimental@$LIBSBML_REVISION
cd libsbml-experimental
svn log -l 1
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS} -fpermissive" -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fpermissive" -DENABLE_SPATIAL=ON -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/tarball/libsbml -DWITH_CPP_NAMESPACE=ON -DLIBSBML_SKIP_SHARED_LIBRARY=ON -DWITH_BZIP2=OFF -DWITH_ZLIB=OFF -DWITH_LIBXML=OFF -DWITH_EXPAT=ON -DLIBEXPAT_INCLUDE_DIR=$BUILD_DIR/expat/include -DLIBEXPAT_LIBRARY=$BUILD_DIR/expat/lib/libexpat.a ..
make -j$N
make install

# include libexpat.a
cp $BUILD_DIR/expat/lib/libexpat.a $BUILD_DIR/tarball/libsbml/lib/.

ls $BUILD_DIR/tarball/*/*
