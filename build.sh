#!/bin/bash
BUILD_DIR=${1:-"C:"}
NPROCS=${2:-2}

LIBSBML_REVISION="26126"
LIBEXPAT_VERSION="R_2_2_7"
SYMENGINE_VERSION="v0.4.0"
GMP_VERSION="6.1.2"
SPDLOG_VERSION="v1.x"
MUPARSER_VERSION="v2.2.6.1"
LIBTIFF_VERSION="v4.0.10"
OSX_DEPLOYMENT_TARGET="10.12"

# make sure we get the right mingw64 version of g++ on appveyor
PATH=/mingw64/bin:$PATH

export MACOSX_DEPLOYMENT_TARGET=${OSX_DEPLOYMENT_TARGET}

echo "LIBSBML_REVISION: ${LIBSBML_REVISION}"
echo "LIBEXPAT_VERSION: ${LIBEXPAT_VERSION}"
echo "SYMENGINE_VERSION: ${SYMENGINE_VERSION}"
echo "GMP_VERSION: ${GMP_VERSION}"
echo "SPDLOG_VERSION: ${SPDLOG_VERSION}"
echo "MUSPARSER_VERSION: ${MUPARSER_VERSION}"
echo "LIBTIFF_VERSION: ${LIBTIFF_VERSION}"
echo "OSX_DEPLOYMENT_TARGET: ${OSX_DEPLOYMENT_TARGET}"

echo "NPROCS: ${NPROCS}"
echo "PATH: ${PATH}"

which g++
g++ --version
which make
make --version
which python
python --version
which cmake
cmake --version

mkdir $BUILD_DIR/tarball

# build static version of libTIFF
git clone -b $LIBTIFF_VERSION --depth 1 https://gitlab.com/libtiff/libtiff.git
cd libtiff
# patch to remove -lm dep on windows
wget https://gist.githubusercontent.com/1480c1/3d981dd54aad0baeed8f822bb156fb68/raw/16ed09dafca3b4b646592c0cde82b122a643ced1/0001-Don-t-use-libm-if-MINGW-due-to-conflict-with-libmsvc.patch
git apply 0001-Don-t-use-libm-if-MINGW-due-to-conflict-with-libmsvc.patch
mkdir cmake-build
cd cmake-build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS} -fpic" -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/tarball/libtiff -DBUILD_SHARED_LIBS=OFF -Djpeg=OFF -Djpeg12=OFF -Djbig=OFF -Dlzma=OFF -Dpixarlog=OFF -Dold-jpeg=OFF -Dzstd=OFF -Dmdi=OFF -Dwebp=OFF -Dzlib=OFF ..
make -j$NPROCS
make test
make install
cd ../../

# build static version of muparser
git clone -b $MUPARSER_VERSION --depth 1 https://github.com/beltoforion/muparser.git
cd muparser
mkdir cmake-build
cd cmake-build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fpic" -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/tarball/muparser -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=ON -DENABLE_OPENMP=OFF -DENABLE_SAMPLES=OFF ..
make -j$NPROCS
make test
make install
cd ../../

# build static version of spdlog
git clone -b $SPDLOG_VERSION --depth 1 https://github.com/gabime/spdlog.git
cd spdlog
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fpic" -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/tarball/spdlog -DSPDLOG_BUILD_TESTS=ON -DSPDLOG_BUILD_EXAMPLE=OFF ..
make -j$NPROCS
make test
make install
cd ../../

# build static version of gmp
# could generate optimised code for a given host, but haven't found safe settings
# instead use safe fallback: --disable-assembly, which should always work albeit slowly
wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.bz2
tar xjf "gmp-${GMP_VERSION}.tar.bz2"
cd gmp-${GMP_VERSION}
./configure --prefix=$BUILD_DIR/tarball/gmp --disable-shared --disable-assembly --enable-static --with-pic --enable-cxx
time make -j$NPROCS
time make check
make install
cd ..

# build static version of symengine
# NOTE: using "-O2" to disable default "-march=native" flag which was causing the
# executable to crash on an older CPU than the one used in the CI build, see:
# https://github.com/symengine/symengine/issues/1579#issuecomment-517036390
git clone -b $SYMENGINE_VERSION --depth 1 https://github.com/symengine/symengine.git
cd symengine
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fpic" -DCMAKE_CXX_FLAGS_RELEASE="-O2" -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/tarball/symengine -DBUILD_BENCHMARKS=OFF -DGMP_INCLUDE_DIR=$BUILD_DIR/tarball/gmp/include -DGMP_LIBRARY=$BUILD_DIR/tarball/gmp/lib/libgmp.a -DCMAKE_PREFIX_PATH=$BUILD_DIR/llvm -DWITH_LLVM=ON -DWITH_COTIRE=OFF ..
time make -j$NPROCS
time make test
make install
cd ../../

# build static version of expat xml library
git clone -b $LIBEXPAT_VERSION --depth 1 https://github.com/libexpat/libexpat.git
cd libexpat
mkdir build
cd build
cmake -G "Unix Makefiles"  -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS} -fpic" -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fpic" -DBUILD_doc=OFF -DBUILD_examples=OFF -DBUILD_shared=off -DBUILD_tests=OFF -DBUILD_tools=OFF -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/tarball/expat ../expat
make -j$NPROCS
make install
cd ../../

# build static version of libSBML including spatial extension
svn -q co https://svn.code.sf.net/p/sbml/code/branches/libsbml-experimental@$LIBSBML_REVISION
cd libsbml-experimental
svn log -l 1
mkdir build
cd build
cmake -G "Unix Makefiles"  -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fpermissive" -DENABLE_SPATIAL=ON -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/tarball/libsbml -DWITH_CPP_NAMESPACE=ON -DLIBSBML_SKIP_SHARED_LIBRARY=ON -DWITH_BZIP2=OFF -DWITH_ZLIB=OFF -DWITH_SWIG=OFF -DWITH_LIBXML=OFF -DWITH_EXPAT=ON -DLIBEXPAT_INCLUDE_DIR=$BUILD_DIR/tarball/expat/include -DLIBEXPAT_LIBRARY=$BUILD_DIR/tarball/expat/lib/libexpat.a ..
time make -j$NPROCS
make install

ls $BUILD_DIR/tarball/*/*
