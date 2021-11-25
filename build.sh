#!/bin/bash

set -e -x

echo "HOST_TRIPLE: ${HOST_TRIPLE}"
echo "LLVM_VERSION: ${LLVM_VERSION}"
echo "QT_VERSION: ${QT_VERSION}"
echo "LIBSBML_VERSION: ${LIBSBML_VERSION}"
echo "LIBEXPAT_VERSION: ${LIBEXPAT_VERSION}"
echo "SYMENGINE_VERSION: ${SYMENGINE_VERSION}"
echo "GMP_VERSION: ${GMP_VERSION}"
echo "MPFR_VERSION: ${MPFR_VERSION}"
echo "SPDLOG_VERSION: ${SPDLOG_VERSION}"
echo "MUSPARSER_VERSION: ${MUPARSER_VERSION}"
echo "LIBTIFF_VERSION: ${LIBTIFF_VERSION}"
echo "FMT_VERSION: ${FMT_VERSION}"
echo "TBB_VERSION: ${TBB_VERSION}"
echo "TBB_OPTIONS: ${TBB_OPTIONS}"
echo "OPENCV_VERSION: ${OPENCV_VERSION}"
echo "CATCH2_VERSION: ${CATCH2_VERSION}"
echo "BENCHMARK_VERSION: ${BENCHMARK_VERSION}"
echo "CGAL_VERSION: ${CGAL_VERSION}"
echo "BOOST_VERSION: ${BOOST_VERSION}"
echo "BOOST_VERSION_: ${BOOST_VERSION_}"
echo "QCUSTOMPLOT_VERSION: ${QCUSTOMPLOT_VERSION}"
echo "CEREAL_VERSION: ${CEREAL_VERSION}"
echo "ZLIB_VERSION: ${ZLIB_VERSION}"

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
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden ${TBB_EXTRA_FLAGS}" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden ${TBB_EXTRA_FLAGS}" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DTBB_STRICT=OFF \
    -DTBB_TEST=OFF
VERBOSE=1 time make tbb -j$NPROCS
#time make test
$SUDOCMD make install
cd ../../
