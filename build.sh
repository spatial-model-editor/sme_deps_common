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

echo "downloading qt & llvm for OS_TARGET: $OS_TARGET"
# download llvm static libs
wget https://github.com/spatial-model-editor/sme_deps_llvm/releases/download/${LLVM_VERSION}/sme_deps_llvm_${OS_TARGET}.tgz
tar xvf sme_deps_llvm_${OS_TARGET}.tgz
# download qt static libs
wget https://github.com/spatial-model-editor/sme_deps_qt/releases/download/${QT_VERSION}/sme_deps_qt_${OS_TARGET}.tgz
tar xvf sme_deps_qt_${OS_TARGET}.tgz
pwd
ls
# copy libs to desired location: workaround for tar -C / not working on windows
if [[ "$OS_TARGET" == *"win"* ]]; then
    mv smelibs /c/
    ls /c/smelibs
else
    $SUDOCMD mv opt/* /opt/
    ls /opt/smelibs
fi

# install Cereal headers
git clone -b $CEREAL_VERSION --depth 1 https://github.com/USCiLab/cereal.git
cd cereal
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DJUST_INSTALL_CEREAL=ON
$SUDOCMD make install
cd ../../

# build static version of QCustomPlot (using our own cmakelists)
wget https://www.qcustomplot.com/release/${QCUSTOMPLOT_VERSION}/QCustomPlot-source.tar.gz
tar xf QCustomPlot-source.tar.gz
cp qcustomplot-source/* qcustomplot/.
cd qcustomplot
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DWITH_QT6=ON
time make -j$NPROCS
$SUDOCMD make install
cd ../../

# install boost headers (just copy headers)
wget https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_}.tar.gz
tar xf boost_${BOOST_VERSION_}.tar.gz
cd boost_${BOOST_VERSION_}
$SUDOCMD cp -r boost $INSTALL_PREFIX/include/.
cd ..

# build static version of Google Benchmark library
git clone -b $BENCHMARK_VERSION --depth 1 https://github.com/google/benchmark.git
cd benchmark
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DBENCHMARK_ENABLE_TESTING=OFF
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of Catch2 library
git clone -b $CATCH2_VERSION --depth 1 https://github.com/catchorg/Catch2.git
cd Catch2
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DBUILD_SHARED_LIBS=OFF \
    -DCATCH_INSTALL_DOCS=OFF \
    -DCATCH_INSTALL_EXTRAS=ON
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of opencv library
git clone -b $OPENCV_VERSION --depth 1 https://github.com/opencv/opencv.git
cd opencv
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
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
    -DBUILD_ZLIB:BOOL=ON \
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
    -DWITH_XINE:BOOL=OFF
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

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
cmake -G "Unix Makefiles" ../expat \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DEXPAT_BUILD_DOCS=OFF \
    -DEXPAT_BUILD_EXAMPLES=OFF \
    -DEXPAT_BUILD_TOOLS=OFF \
    -DEXPAT_SHARED_LIBS=OFF \
    -DEXPAT_BUILD_TESTS:BOOL=OFF
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of libSBML including spatial extension
git clone -b $LIBSBML_VERSION --depth 1 https://github.com/sbmlteam/libsbml.git
cd libsbml
git status
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DENABLE_SPATIAL=ON \
    -DWITH_CPP_NAMESPACE=ON \
    -DLIBSBML_SKIP_SHARED_LIBRARY=ON \
    -DWITH_BZIP2=OFF \
    -DWITH_ZLIB=OFF \
    -DWITH_SWIG=OFF \
    -DWITH_LIBXML=OFF \
    -DWITH_EXPAT=ON \
    -DLIBEXPAT_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DLIBEXPAT_LIBRARY=$INSTALL_PREFIX/lib/libexpat.a
time make -j$NPROCS
$SUDOCMD make install
cd ../../

# build static version of fmt
git clone -b $FMT_VERSION --depth 1 https://github.com/fmtlib/fmt.git
cd fmt
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_STANDARD=17 \
    -DFMT_DOC=OFF \
    -DFMT_TEST:BOOL=OFF
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of libTIFF
git clone -b $LIBTIFF_VERSION --depth 1 https://gitlab.com/libtiff/libtiff.git
cd libtiff
mkdir cmake-build
cd cmake-build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
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
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of muparser
git clone -b $MUPARSER_VERSION --depth 1 https://github.com/beltoforion/muparser.git
cd muparser
mkdir cmake-build
cd cmake-build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DBUILD_TESTING=OFF \
    -DENABLE_OPENMP=OFF \
    -DENABLE_SAMPLES=OFF
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of spdlog
git clone -b $SPDLOG_VERSION --depth 1 https://github.com/gabime/spdlog.git
cd spdlog
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DSPDLOG_BUILD_TESTS=OFF \
    -DSPDLOG_BUILD_EXAMPLE=OFF \
    -DSPDLOG_FMT_EXTERNAL=ON \
    -DSPDLOG_NO_THREAD_ID=ON \
    -DSPDLOG_NO_ATOMIC_LEVELS=ON \
    -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of gmp
# --host=amd64-*, aka x86_64, i.e. support all 64-bit cpus: no instructions higher than SSE2 are used
wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz
# workaround for msys2 (`tar xf file.tar.xz` hangs): https://github.com/msys2/MSYS2-packages/issues/1548
xz -dc gmp-${GMP_VERSION}.tar.xz | tar -x --file=-
cd gmp-${GMP_VERSION}
./configure \
    --prefix=$INSTALL_PREFIX \
    --disable-shared \
    --host=${HOST_TRIPLE} \
    --enable-static \
    --with-pic \
    --enable-cxx
time make -j$NPROCS
#time make check
$SUDOCMD make install
cd ..

# build static version of mpfr
wget https://www.mpfr.org/mpfr-current/mpfr-${MPFR_VERSION}.tar.xz
# workaround for msys2 (`tar xf file.tar.xz` hangs): https://github.com/msys2/MSYS2-packages/issues/1548
xz -dc mpfr-${MPFR_VERSION}.tar.xz | tar -x --file=-
cd mpfr-${MPFR_VERSION}
./configure \
    --prefix=$INSTALL_PREFIX \
    --disable-shared \
    --host=amd64-pc-linux-gnu \
    --enable-static \
    --with-pic \
    --with-gmp-lib=$INSTALL_PREFIX/lib \
    --with-gmp-include=$INSTALL_PREFIX/include
time make -j$NPROCS
#time make check
$SUDOCMD make install
cd ..

# install CGAL (should just be copying headers)
git clone -b $CGAL_VERSION --depth 1 https://github.com/CGAL/cgal.git
cd cgal
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DWITH_CGAL_ImageIO=OFF \
    -DWITH_CGAL_Qt5=OFF
$SUDOCMD make install
cd ../../

# build static version of symengine
git clone -b $SYMENGINE_VERSION --depth 1 https://github.com/symengine/symengine.git
cd symengine
mkdir build
cd build
cmake -G "Unix Makefiles" .. \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DBUILD_BENCHMARKS=OFF \
    -DGMP_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DGMP_LIBRARY=$INSTALL_PREFIX/lib/libgmp.a \
    -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX \
    -DWITH_LLVM=ON \
    -DWITH_COTIRE=OFF \
    -DWITH_SYMENGINE_THREAD_SAFE=OFF \
    -DBUILD_TESTS=OFF
time make -j$NPROCS
#time make test
$SUDOCMD make install
cd ../../

mkdir artefacts
cd artefacts
tar -zcvf sme_deps_common_${OS_TARGET}.tgz $INSTALL_PREFIX/*
