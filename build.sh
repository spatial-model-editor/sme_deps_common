#!/bin/bash
source source.sh

LIBSBML_VERSION="development"
LIBEXPAT_VERSION="R_2_2_9"
SYMENGINE_VERSION="v0.6.0"
# symengine note: -DWITH_CPP14 flag can be removed with next release
GMP_VERSION="6.1.2"
SPDLOG_VERSION="v1.7.0"
MUPARSER_VERSION="v2.2.6.1"
LIBTIFF_VERSION="master"
#libtiff note: we want commit bd03e1a2 which fixed libm issue with mingw, 
# but this is not in release v4.1.0, so using master branch until next release
FMT_VERSION="7.0.1"
TBB_VERSION="v2020.3"

echo "LIBSBML_VERSION: ${LIBSBML_VERSION}"
echo "LIBEXPAT_VERSION: ${LIBEXPAT_VERSION}"
echo "SYMENGINE_VERSION: ${SYMENGINE_VERSION}"
echo "GMP_VERSION: ${GMP_VERSION}"
echo "SPDLOG_VERSION: ${SPDLOG_VERSION}"
echo "MUSPARSER_VERSION: ${MUPARSER_VERSION}"
echo "LIBTIFF_VERSION: ${LIBTIFF_VERSION}"
echo "FMT_VERSION: ${FMT_VERSION}"
echo "TBB_VERSION: ${TBB_VERSION}"
echo "TBB_OPTIONS: ${TBB_OPTIONS}"

NPROCS=2
echo "NPROCS: ${NPROCS}"
echo "PATH: ${PATH}"
echo "SUDOCMD: ${SUDOCMD}"

which g++
g++ --version
which make
make --version
which python
python --version
which cmake
cmake --version

# build static version of tbb
git clone -b $TBB_VERSION --depth 1 https://github.com/intel/tbb.git
cd tbb
time make tbb $TBB_OPTIONS stdver=c++17 extra_inc=big_iron.inc -j$NPROCS
ls build/*_release
$SUDOCMD mkdir -p $INSTALL_PREFIX/lib
$SUDOCMD cp build/*_release/*.a $INSTALL_PREFIX/lib
$SUDOCMD mkdir -p $INSTALL_PREFIX/include
$SUDOCMD cp -r include/tbb $INSTALL_PREFIX/include/.
ls $INSTALL_PREFIX/*/*
cd ../

# build static version of expat xml library
git clone -b $LIBEXPAT_VERSION --depth 1 https://github.com/libexpat/libexpat.git
cd libexpat
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TOOLS=OFF -DEXPAT_SHARED_LIBS=OFF ../expat
time make -j$NPROCS
make test
$SUDOCMD make install
cd ../../

# build static version of libSBML including spatial extension
git clone -b $LIBSBML_VERSION --depth 1 https://github.com/sbmlteam/libsbml.git
cd libsbml
git status
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DENABLE_SPATIAL=ON -DWITH_CPP_NAMESPACE=ON -DLIBSBML_SKIP_SHARED_LIBRARY=ON -DWITH_BZIP2=OFF -DWITH_ZLIB=OFF -DWITH_SWIG=OFF -DWITH_LIBXML=OFF -DWITH_EXPAT=ON -DLIBEXPAT_INCLUDE_DIR=$INSTALL_PREFIX/include -DLIBEXPAT_LIBRARY=$INSTALL_PREFIX/lib/libexpat.a ..
time make -j$NPROCS
$SUDOCMD make install
cd ../../

# build static version of fmt
git clone -b $FMT_VERSION --depth 1 https://github.com/fmtlib/fmt.git
cd fmt
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_CXX_STANDARD=17 -DFMT_DOC=OFF ..
make -j$NPROCS
make test
$SUDOCMD make install
cd ../../

# build static version of libTIFF
git clone -b $LIBTIFF_VERSION --depth 1 https://gitlab.com/libtiff/libtiff.git
cd libtiff
mkdir cmake-build
cd cmake-build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -Djpeg=OFF -Djpeg12=OFF -Djbig=OFF -Dlzma=OFF -Dpixarlog=OFF -Dold-jpeg=OFF -Dzstd=OFF -Dmdi=OFF -Dwebp=OFF -Dzlib=OFF -DGLUT_INCLUDE_DIR=GLUT_INCLUDE_DIR-NOTFOUND -DOPENGL_INCLUDE_DIR=OPENGL_INCLUDE_DIR-NOTFOUND ..
make -j$NPROCS
make test
$SUDOCMD make install
cd ../../

# build static version of muparser
git clone -b $MUPARSER_VERSION --depth 1 https://github.com/beltoforion/muparser.git
cd muparser
mkdir cmake-build
cd cmake-build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_TESTING=ON -DENABLE_OPENMP=OFF -DENABLE_SAMPLES=OFF ..
make -j$NPROCS
make test
$SUDOCMD make install
cd ../../

# build static version of spdlog
git clone -b $SPDLOG_VERSION --depth 1 https://github.com/gabime/spdlog.git
cd spdlog
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DSPDLOG_BUILD_TESTS=ON -DSPDLOG_BUILD_EXAMPLE=OFF -DSPDLOG_FMT_EXTERNAL=ON -DSPDLOG_NO_THREAD_ID=ON -DSPDLOG_NO_ATOMIC_LEVELS=ON -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX ..
make -j$NPROCS
make test
$SUDOCMD make install
cd ../../

# build static version of gmp
# could generate optimised code for a given host, but haven't found safe settings
# instead use safe fallback: --disable-assembly, which should always work albeit slowly
wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz
# workaround for msys2 (`tar xf file.tar.xz` hangs): https://github.com/msys2/MSYS2-packages/issues/1548
xz -dc gmp-${GMP_VERSION}.tar.xz | tar -x --file=-
cd gmp-${GMP_VERSION}
./configure --prefix=$INSTALL_PREFIX --disable-shared --disable-assembly --enable-static --with-pic --enable-cxx
time make -j$NPROCS
time make check
$SUDOCMD make install
cd ..

# build static version of symengine
git clone -b $SYMENGINE_VERSION --depth 1 https://github.com/symengine/symengine.git
cd symengine
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_BENCHMARKS=OFF -DGMP_INCLUDE_DIR=$INSTALL_PREFIX/include -DGMP_LIBRARY=$INSTALL_PREFIX/lib/libgmp.a -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX -DWITH_LLVM=ON -DWITH_COTIRE=OFF -DWITH_SYMENGINE_THREAD_SAFE=OFF -DWITH_CPP14=ON ..
time make -j$NPROCS
time make test
$SUDOCMD make install
cd ../../
