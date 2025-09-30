#!/bin/bash

set -e -x

echo "HOST_TRIPLE: ${HOST_TRIPLE}"
echo "LIBSBML_VERSION: ${LIBSBML_VERSION}"
echo "LIBEXPAT_VERSION: ${LIBEXPAT_VERSION}"
echo "SYMENGINE_VERSION: ${SYMENGINE_VERSION}"
echo "GMP_VERSION: ${GMP_VERSION}"
echo "MPFR_VERSION: ${MPFR_VERSION}"
echo "SPDLOG_VERSION: ${SPDLOG_VERSION}"
echo "LIBTIFF_VERSION: ${LIBTIFF_VERSION}"
echo "FMT_VERSION: ${FMT_VERSION}"
echo "TBB_VERSION: ${TBB_VERSION}"
echo "OPENCV_VERSION: ${OPENCV_VERSION}"
echo "CATCH2_VERSION: ${CATCH2_VERSION}"
echo "BENCHMARK_VERSION: ${BENCHMARK_VERSION}"
echo "CGAL_VERSION: ${CGAL_VERSION}"
echo "BOOST_VERSION: ${BOOST_VERSION}"
echo "BOOST_VERSION_: ${BOOST_VERSION_}"
echo "BOOST_INSTALL_PREFIX: ${BOOST_INSTALL_PREFIX}"
echo "BOOST_BOOTSTRAP_OPTIONS: ${BOOST_BOOTSTRAP_OPTIONS}"
echo "BOOST_B2_OPTIONS: ${BOOST_B2_OPTIONS}"
echo "QCUSTOMPLOT_VERSION: ${QCUSTOMPLOT_VERSION}"
echo "CEREAL_VERSION: ${CEREAL_VERSION}"
echo "PAGMO_VERSION: ${PAGMO_VERSION}"
echo "BZIP2_VERSION: ${BZIP2_VERSION}"
echo "ZIPPER_VERSION: ${ZIPPER_VERSION}"
echo "COMBINE_VERSION: ${COMBINE_VERSION}"
echo "FUNCTION2_VERSION: ${FUNCTION2_VERSION}"
echo "VTK_VERSION: ${VTK_VERSION}"
echo "SCOTCH_VERSION: ${SCOTCH_VERSION}"
echo "NLOPT_VERSION: ${NLOPT_VERSION}"

export "CMAKE_POLICY_VERSION_MINIMUM=3.5"

NPROCS=4
echo "NPROCS: ${NPROCS}"
echo "PATH: ${PATH}"
echo "SUDO_CMD: ${SUDO_CMD}"

which g++
g++ --version
which make
make --version
which python
python --version
which cmake
cmake --version

# build static version of nlopt (required by pagmo)
git clone -b $NLOPT_VERSION --depth 1 https://github.com/stevengj/nlopt.git
cd nlopt
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DNLOPT_FORTRAN=OFF \
    -DNLOPT_GUILE=OFF \
    -DNLOPT_JAVA=OFF \
    -DNLOPT_MATLAB=OFF \
    -DNLOPT_OCTAVE=OFF \
    -DNLOPT_PYTHON=OFF \
    -DNLOPT_SWIG=OFF
time ninja
${SUDO_CMD} ninja install
cd ../../

# install function2 headers
git clone -b $FUNCTION2_VERSION --depth 1 https://github.com/Naios/function2.git
cd function2
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
${SUDO_CMD} ninja install
cd ../../

# build static version of bzip2
git clone -b ${BZIP2_VERSION} --depth 1 https://gitlab.com/bzip2/bzip2.git
cd bzip2
# copy of existing cflags from Makefile with additional -fPIC
BZIP2_CFLAGS="-O2 -g -D_FILE_OFFSET_BITS=64 -fPIC"
# also specify CC if CC env var is set
if [ -z "$CC" ]; then make "CFLAGS=${BZIP2_CFLAGS}" -j${NPROCS}; else make CC=${CC} "CFLAGS=${BZIP2_CFLAGS}" -j${NPROCS}; fi
make install PREFIX="$INSTALL_PREFIX"
cd ../

# install Cereal headers
git clone -b $CEREAL_VERSION --depth 1 https://github.com/USCiLab/cereal.git
cd cereal
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DJUST_INSTALL_CEREAL=ON
${SUDO_CMD} ninja install
cd ../../

# build static version of QCustomPlot (using our own cmakelists)
wget https://www.qcustomplot.com/release/${QCUSTOMPLOT_VERSION}/QCustomPlot-source.tar.gz
tar xf QCustomPlot-source.tar.gz
cp qcustomplot-source/* qcustomplot/.
cd qcustomplot
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX}/include \
    -DZLIB_LIBRARY_RELEASE=${INSTALL_PREFIX}/lib/libz.a \
    -DWITH_QT6=ON
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of boost serialization & install headers
wget https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_}.tar.gz
tar xf boost_${BOOST_VERSION_}.tar.gz
cd boost_${BOOST_VERSION_}
./bootstrap.sh ${BOOST_BOOTSTRAP_OPTIONS} --prefix="${BOOST_INSTALL_PREFIX}" --with-libraries=serialization
${SUDO_CMD} ./b2 ${BOOST_B2_OPTIONS} link=static install
cd ..

# build static version of Google Benchmark library
git clone -b $BENCHMARK_VERSION --depth 1 https://github.com/google/benchmark.git
cd benchmark
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DBENCHMARK_ENABLE_TESTING=OFF
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of Catch2 library
git clone -b $CATCH2_VERSION --depth 1 https://github.com/catchorg/Catch2.git
cd Catch2
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DBUILD_SHARED_LIBS=OFF \
    -DCATCH_INSTALL_DOCS=OFF \
    -DCATCH_INSTALL_EXTRAS=ON
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of opencv library
git clone -b $OPENCV_VERSION --depth 1 https://github.com/opencv/opencv.git
cd opencv
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_opencv_calib3d=OFF \
    -DBUILD_opencv_core=ON \
    -DBUILD_opencv_dnn=OFF \
    -DBUILD_opencv_features2d=OFF \
    -DBUILD_opencv_flann=OFF \
    -DBUILD_opencv_gapi=OFF \
    -DBUILD_opencv_highgui=OFF \
    -DBUILD_opencv_imgcodecs=OFF \
    -DBUILD_opencv_imgproc=ON \
    -DBUILD_opencv_java_bindings_generator=OFF \
    -DBUILD_opencv_js=OFF \
    -DBUILD_opencv_ml=OFF \
    -DBUILD_opencv_objdetect=OFF \
    -DBUILD_opencv_photo=OFF \
    -DBUILD_opencv_python_bindings_generator=OFF \
    -DBUILD_opencv_python_tests=OFF \
    -DBUILD_opencv_stitching=OFF \
    -DBUILD_opencv_ts=OFF \
    -DBUILD_opencv_video=OFF \
    -DBUILD_opencv_videoio=OFF \
    -DBUILD_opencv_world=OFF \
    -DBUILD_CUDA_STUBS:BOOL=OFF \
    -DBUILD_DOCS:BOOL=OFF \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_FAT_JAVA_LIB:BOOL=OFF \
    -DBUILD_IPP_IW:BOOL=OFF \
    -DBUILD_ITT:BOOL=OFF \
    -DBUILD_JASPER:BOOL=OFF \
    -DBUILD_JAVA:BOOL=OFF \
    -DBUILD_JPEG:BOOL=OFF \
    -DBUILD_OPENEXR:BOOL=OFF \
    -DBUILD_PACKAGE:BOOL=OFF \
    -DBUILD_PERF_TESTS:BOOL=OFF \
    -DBUILD_PNG:BOOL=OFF \
    -DBUILD_PROTOBUF:BOOL=OFF \
    -DBUILD_SHARED_LIBS:BOOL=OFF \
    -DBUILD_TBB:BOOL=OFF \
    -DBUILD_TESTS:BOOL=OFF \
    -DBUILD_TIFF:BOOL=OFF \
    -DBUILD_USE_SYMLINKS:BOOL=OFF \
    -DBUILD_WEBP:BOOL=OFF \
    -DBUILD_WITH_DEBUG_INFO:BOOL=OFF \
    -DBUILD_WITH_DYNAMIC_IPP:BOOL=OFF \
    -DBUILD_ZLIB:BOOL=OFF \
    -DWITH_1394:BOOL=OFF \
    -DWITH_ADE:BOOL=OFF \
    -DWITH_ARAVIS:BOOL=OFF \
    -DWITH_CLP:BOOL=OFF \
    -DWITH_CUDA:BOOL=OFF \
    -DWITH_EIGEN:BOOL=OFF \
    -DWITH_FFMPEG:BOOL=OFF \
    -DWITH_FREETYPE:BOOL=OFF \
    -DWITH_GDAL:BOOL=OFF \
    -DWITH_GDCM:BOOL=OFF \
    -DWITH_GPHOTO2:BOOL=OFF \
    -DWITH_GSTREAMER:BOOL=OFF \
    -DWITH_GTK:BOOL=OFF \
    -DWITH_GTK_2_X:BOOL=OFF \
    -DWITH_HALIDE:BOOL=OFF \
    -DWITH_HPX:BOOL=OFF \
    -DWITH_IMGCODEC_HDR:BOOL=OFF \
    -DWITH_IMGCODEC_PFM:BOOL=OFF \
    -DWITH_IMGCODEC_PXM:BOOL=OFF \
    -DWITH_IMGCODEC_SUNRASTER:BOOL=OFF \
    -DWITH_INF_ENGINE:BOOL=OFF \
    -DWITH_IPP:BOOL=OFF \
    -DWITH_ITT:BOOL=OFF \
    -DWITH_JASPER:BOOL=OFF \
    -DWITH_JPEG:BOOL=OFF \
    -DWITH_LAPACK:BOOL=OFF \
    -DWITH_LIBREALSENSE:BOOL=OFF \
    -DWITH_MFX:BOOL=OFF \
    -DWITH_NGRAPH:BOOL=OFF \
    -DWITH_OPENCL:BOOL=OFF \
    -DWITH_OPENCLAMDBLAS:BOOL=OFF \
    -DWITH_OPENCLAMDFFT:BOOL=OFF \
    -DWITH_OPENCL_SVM:BOOL=OFF \
    -DWITH_OPENEXR:BOOL=OFF \
    -DWITH_OPENGL:BOOL=OFF \
    -DWITH_OPENJPEG:BOOL=OFF \
    -DWITH_OPENMP:BOOL=OFF \
    -DWITH_OPENNI:BOOL=OFF \
    -DWITH_OPENNI2:BOOL=OFF \
    -DWITH_OPENVX:BOOL=OFF \
    -DWITH_PLAIDML:BOOL=OFF \
    -DWITH_PNG:BOOL=OFF \
    -DWITH_PROTOBUF:BOOL=OFF \
    -DWITH_PTHREADS_PF:BOOL=OFF \
    -DWITH_PVAPI:BOOL=OFF \
    -DWITH_QT:BOOL=OFF \
    -DWITH_QUIRC:BOOL=OFF \
    -DWITH_TBB:BOOL=OFF \
    -DWITH_TIFF:BOOL=OFF \
    -DWITH_V4L:BOOL=OFF \
    -DWITH_VA:BOOL=OFF \
    -DWITH_VA_INTEL:BOOL=OFF \
    -DWITH_VTK:BOOL=OFF \
    -DWITH_VULKAN:BOOL=OFF \
    -DWITH_WEBP:BOOL=OFF \
    -DWITH_XIMEA:BOOL=OFF \
    -DWITH_XINE:BOOL=OFF \
    -DZLIB_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DZLIB_LIBRARY_RELEASE=$INSTALL_PREFIX/lib/libz.a
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of oneTBB
git clone -b $TBB_VERSION --depth 1 https://github.com/oneapi-src/oneTBB.git
cd oneTBB
# patch for "c++.exe: fatal error: input file '/dev/null' is the same as output file" issue on windows due to cmake execute_process quoting command
# line 50 of https://github.com/uxlfoundation/oneTBB/commit/377e6c3b1719f8cc7b68f9d0939e652d7e3bf776#diff-08a9ef6921a1ae25a4447b8a4ff5740038771e549fb6f0ff69dafb35c342a8b8R5
# instead of calling c++ to get the binutils version we get it from CMAKE_CXX_COMPILER_LINKER_VERSION
# note: this works fine for us as we use binutils for linker and assembler, haven't checked if it also works if a different linker is used.
git apply --ignore-space-change --ignore-whitespace --verbose ../tbb.diff
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DTBB_ENABLE_IPO="$TBB_ENABLE_IPO" \
    -DTBB_STRICT=OFF \
    -DTBB_TEST=OFF
VERBOSE=1 time ninja tbb
${SUDO_CMD} ninja install
cd ../../

# build static version of oneDPL
git clone -b $DPL_VERSION --depth 1 https://github.com/oneapi-src/oneDPL
cd oneDPL
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DONEDPL_BACKEND="tbb"
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of pagmo
git clone -b $PAGMO_VERSION --depth 1 https://github.com/esa/pagmo2.git
cd pagmo2
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" \
    -DPAGMO_BUILD_STATIC_LIBRARY=ON \
    -DPAGMO_WITH_NLOPT=ON \
    -DPAGMO_BUILD_TESTS=OFF
VERBOSE=1 time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of expat xml library
git clone -b $LIBEXPAT_VERSION --depth 1 https://github.com/libexpat/libexpat.git
cd libexpat
mkdir build
cd build
cmake -GNinja ../expat \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DEXPAT_BUILD_DOCS=OFF \
    -DEXPAT_BUILD_EXAMPLES=OFF \
    -DEXPAT_BUILD_TOOLS=OFF \
    -DEXPAT_SHARED_LIBS=OFF \
    -DEXPAT_BUILD_TESTS:BOOL=OFF
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of libSBML including spatial extension
git clone -b $LIBSBML_VERSION --depth 1 https://github.com/sbmlteam/libsbml.git
cd libsbml
# patch to add missing cstdint header which causes error with gcc 15
git apply --ignore-space-change --ignore-whitespace --verbose ../libsbml.diff
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DENABLE_SPATIAL=ON \
    -DWITH_CPP_NAMESPACE=ON \
    -DWITH_THREADSAFE_PARSER=ON \
    -DLIBSBML_SKIP_SHARED_LIBRARY=ON \
    -DWITH_BZIP2=ON \
    -DLIBBZ_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DLIBBZ_LIBRARY=$INSTALL_PREFIX/lib/libbz2.a \
    -DWITH_ZLIB=ON \
    -DLIBZ_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DLIBZ_LIBRARY=$INSTALL_PREFIX/lib/libz.a \
    -DWITH_SWIG=OFF \
    -DWITH_LIBXML=OFF \
    -DWITH_EXPAT=ON \
    -DEXPAT_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DEXPAT_LIBRARY=$INSTALL_PREFIX/lib/libexpat.a
time ninja
${SUDO_CMD} ninja install
cd ../../

# libCombine
git clone -b $COMBINE_VERSION --depth 1 https://github.com/sbmlteam/libCombine.git
cd libCombine
# get zipper submodule (and it's minizip submodule)
git submodule update --init --recursive
cd submodules/zipper
git checkout $ZIPPER_VERSION
cd ../../
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$BOOST_INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DLIBCOMBINE_SKIP_SHARED_LIBRARY=ON \
    -DWITH_CPP_NAMESPACE=ON \
    -DCMAKE_PREFIX_PATH="$BOOST_INSTALL_PREFIX;$BOOST_INSTALL_PREFIX/lib/cmake" \
    -DEXTRA_LIBS="$BOOST_INSTALL_PREFIX/lib/libz.a;$BOOST_INSTALL_PREFIX/lib/libbz2.a;$BOOST_INSTALL_PREFIX/lib/libexpat.a" \
    -DZLIB_INCLUDE_DIR=$BOOST_INSTALL_PREFIX/include \
    -DZLIB_LIBRARY=$BOOST_INSTALL_PREFIX/lib/libz.a
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of fmt
git clone -b $FMT_VERSION --depth 1 https://github.com/fmtlib/fmt.git
cd fmt
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_DOC=OFF \
    -DFMT_TEST:BOOL=OFF
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of libTIFF
git clone -b $LIBTIFF_VERSION --depth 1 https://gitlab.com/libtiff/libtiff.git
cd libtiff
# apply patch to fix "CMath target not found error" when this installed libtiff is used
# (note libtiff cmake install is broken for all dependencies, so for now we just disable them all)
git apply --ignore-space-change --ignore-whitespace --verbose ../libtiff.diff
mkdir cmake-build
cd cmake-build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -Djpeg=OFF \
    -Djpeg12=OFF \
    -Djbig=OFF \
    -Dlzma=OFF \
    -Dlibdeflate=OFF \
    -Dpixarlog=OFF \
    -Dold-jpeg=OFF \
    -Dzstd=OFF \
    -Dmdi=OFF \
    -Dwebp=OFF \
    -Dzlib=OFF \
    -DGLUT_INCLUDE_DIR=GLUT_INCLUDE_DIR-NOTFOUND \
    -DOPENGL_INCLUDE_DIR=OPENGL_INCLUDE_DIR-NOTFOUND
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of spdlog
git clone -b $SPDLOG_VERSION --depth 1 https://github.com/gabime/spdlog.git
cd spdlog
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_STANDARD=20 \
    -DSPDLOG_BUILD_TESTS=OFF \
    -DSPDLOG_BUILD_EXAMPLE=OFF \
    -DSPDLOG_FMT_EXTERNAL=ON \
    -DSPDLOG_NO_THREAD_ID=ON \
    -DSPDLOG_NO_ATOMIC_LEVELS=ON \
    -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of gmp
# temporary workaround for gmp blacklisting github ips:
# wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz
wget https://github.com/spatial-model-editor/spatial-model-editor.github.io/releases/download/1.0.0/gmp-${GMP_VERSION}.tar.xz
# workaround for msys2 (`tar xf file.tar.xz` hangs): https://github.com/msys2/MSYS2-packages/issues/1548
xz -dc gmp-${GMP_VERSION}.tar.xz | tar -x --file=-
cd gmp-${GMP_VERSION}
# note: includes this patch for configure error with gcc15 as it defaults to c23 (from https://gitlab.archlinux.org/archlinux/packaging/packages/gmp/-/blob/main/gmp-gcc-15.patch?ref_type=heads)
# (the following two commands were ran on the files hosted above)
### git apply --ignore-space-change --ignore-whitespace --verbose ../gmp.diff
### autoreconf -i -f
./configure \
    --prefix=$INSTALL_PREFIX \
    --disable-shared \
    --host=${HOST_TRIPLE} \
    --enable-static \
    --with-pic \
    --enable-cxx || (cat config.log && exit 1)
time make -j$NPROCS
${SUDO_CMD} make install
cd ..

# build static version of mpfr
wget https://www.mpfr.org/mpfr-${MPFR_VERSION}/mpfr-${MPFR_VERSION}.tar.xz
# workaround for msys2 (`tar xf file.tar.xz` hangs): https://github.com/msys2/MSYS2-packages/issues/1548
xz -dc mpfr-${MPFR_VERSION}.tar.xz | tar -x --file=-
cd mpfr-${MPFR_VERSION}
./configure \
    --prefix=$INSTALL_PREFIX \
    --disable-shared \
    --host=${HOST_TRIPLE} \
    --enable-static \
    --with-pic \
    --with-gmp-lib=$INSTALL_PREFIX/lib \
    --with-gmp-include=$INSTALL_PREFIX/include
time make -j$NPROCS
${SUDO_CMD} make install
cd ..

# install CGAL (should just be copying headers)
git clone -b $CGAL_VERSION --depth 1 https://github.com/CGAL/cgal.git
cd cgal
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DWITH_CGAL_ImageIO=OFF \
    -DWITH_CGAL_Qt5=OFF
${SUDO_CMD} ninja install
cd ../../

# build static version of symengine
git clone -b $SYMENGINE_VERSION --depth 1 https://github.com/symengine/symengine.git
cd symengine
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DBUILD_BENCHMARKS=OFF \
    -DGMP_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DGMP_LIBRARY=$INSTALL_PREFIX/lib/libgmp.a \
    -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX \
    -DWITH_LLVM=ON \
    -DWITH_COTIRE=OFF \
    -DWITH_SYSTEM_CEREAL=ON \
    -DWITH_SYMENGINE_THREAD_SAFE=ON \
    -DBUILD_TESTS=OFF
time ninja
${SUDO_CMD} ninja install
cd ../../

# combine the static libs implicitly required by qt's bundled freetype lib into a single .a lib for vtk to use
if [ "$RUNNER_OS" != "Linux" ]; then
    if [ "$RUNNER_OS" == "macOS" ]; then
        # combine using libtool on mac
        libtool -static -o ${INSTALL_PREFIX}/lib/libCombinedFreetype.a ${INSTALL_PREFIX}/lib/libQt6BundledFreetype.a ${INSTALL_PREFIX}/lib/libQt6BundledLibpng.a ${INSTALL_PREFIX}/lib/libz.a
    elif [ "$RUNNER_OS" == "Windows" ]; then
        # combine using ld and ar on msys
        ld -r -o libCombinedFreetype.o ${INSTALL_PREFIX}/lib/libQt6BundledFreetype.a ${INSTALL_PREFIX}/lib/libQt6BundledLibpng.a ${INSTALL_PREFIX}/lib/libz.a
        ar rcs ${INSTALL_PREFIX}/lib/libCombinedFreetype.a libCombinedFreetype.o
    fi
    VTK_OPTIONS="-DFREETYPE_LIBRARY_RELEASE=${INSTALL_PREFIX}/lib/libCombinedFreetype.a -DFREETYPE_INCLUDE_DIR_freetype2=${INSTALL_PREFIX}/include/QtFreetype -DFREETYPE_INCLUDE_DIR_ft2build=${INSTALL_PREFIX}/include/QtFreetype"
fi

# build minimal static version of VTK including GUISupportQt and RenderingQt modules
git clone -b $VTK_VERSION --depth 1 https://github.com/Kitware/VTK.git
cd VTK
git apply --ignore-space-change --ignore-whitespace --verbose ../vtk.diff
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DVTK_GROUP_ENABLE_StandAlone=DONT_WANT \
    -DVTK_GROUP_ENABLE_Rendering=YES \
    -DVTK_MODULE_ENABLE_VTK_GUISupportQt=YES \
    -DVTK_MODULE_ENABLE_VTK_RenderingQt=YES \
    -DVTK_MODULE_USE_EXTERNAL_VTK_expat=ON \
    -DEXPAT_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DEXPAT_LIBRARY=$INSTALL_PREFIX/lib/libexpat.a \
    -DVTK_MODULE_USE_EXTERNAL_VTK_fmt=ON \
    -DVTK_MODULE_USE_EXTERNAL_VTK_tiff=ON \
    -DTIFF_INCLUDE_DIR=${INSTALL_PREFIX}/include \
    -DTIFF_LIBRARY_RELEASE=${INSTALL_PREFIX}/lib/libtiff.a \
    -DVTK_MODULE_USE_EXTERNAL_VTK_zlib=ON \
    -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX}/include \
    -DZLIB_LIBRARY_RELEASE=${INSTALL_PREFIX}/lib/libz.a \
    -DVTK_MODULE_USE_EXTERNAL_VTK_freetype=ON \
    -DVTK_LEGACY_REMOVE=ON \
    -DVTK_USE_FUTURE_CONST=ON \
    -DVTK_USE_FUTURE_BOOL=ON \
    -DVTK_ENABLE_LOGGING=OFF \
    -DVTK_USE_CUDA=OFF \
    -DVTK_USE_MPI=OFF \
    -DVTK_ENABLE_WRAPPING=OFF \
    ${VTK_OPTIONS}
time ninja
${SUDO_CMD} ninja install
cd ../../

# Scotch (includes METIS compatibility library)
git clone -b $SCOTCH_VERSION --depth 1 https://gitlab.inria.fr/scotch/scotch.git
cd scotch
mkdir build
cd build
cmake -GNinja .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DBUILD_PTSCOTCH=OFF \
    -DBUILD_LIBESMUMPS=OFF \
    -DBUILD_FORTRAN=OFF \
    -DUSE_LZMA=OFF \
    -DUSE_ZLIB=ON \
    -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX}/include \
    -DZLIB_LIBRARY_RELEASE=${INSTALL_PREFIX}/lib/libz.a \
    -DUSE_BZ2=ON \
    -DBZIP2_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DBZIP2_LIBRARY_RELEASE=$INSTALL_PREFIX/lib/libbz2.a
time ninja
${SUDO_CMD} ninja install
cd ../../

ccache --show-stats

mkdir artefacts
cd artefacts
tar -zcvf sme_deps_common_${OS}.tgz $INSTALL_PREFIX/*
