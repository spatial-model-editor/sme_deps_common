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
OPENCV_VERSION="4.4.0"

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
echo "OPENCV_VERSION: ${OPENCV_VERSION}"

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

# build static version of opencv library
git clone -b $OPENCV_VERSION --depth 1 https://github.com/opencv/opencv.git
cd opencv
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_opencv_apps=OFF -DBUILD_opencv_calib3d=OFF -DBUILD_opencv_core=ON -DBUILD_opencv_dnn=OFF -DBUILD_opencv_features2d=OFF -DBUILD_opencv_flann=OFF -DBUILD_opencv_gapi=OFF -DBUILD_opencv_highgui=OFF -DBUILD_opencv_imgcodecs=OFF -DBUILD_opencv_imgproc=ON -DBUILD_opencv_java_bindings_generator=OFF -DBUILD_opencv_js=OFF -DBUILD_opencv_ml=OFF -DBUILD_opencv_objdetect=OFF -DBUILD_opencv_photo=OFF -DBUILD_opencv_python_bindings_generator=OFF -DBUILD_opencv_python_tests=OFF -DBUILD_opencv_stitching=OFF -DBUILD_opencv_ts=OFF -DBUILD_opencv_video=OFF -DBUILD_opencv_videoio=OFF -DBUILD_opencv_world=OFF -DBUILD_CUDA_STUBS:BOOL=OFF -DBUILD_DOCS:BOOL=OFF -DBUILD_EXAMPLES:BOOL=OFF -DBUILD_FAT_JAVA_LIB:BOOL=OFF -DBUILD_IPP_IW:BOOL=OFF -DBUILD_ITT:BOOL=OFF -DBUILD_JASPER:BOOL=OFF -DBUILD_JAVA:BOOL=OFF -DBUILD_JPEG:BOOL=OFF -DBUILD_OPENEXR:BOOL=OFF -DBUILD_PACKAGE:BOOL=OFF -DBUILD_PERF_TESTS:BOOL=OFF -DBUILD_PNG:BOOL=OFF -DBUILD_PROTOBUF:BOOL=OFF -DBUILD_SHARED_LIBS:BOOL=OFF -DBUILD_TBB:BOOL=OFF -DBUILD_TESTS:BOOL=OFF -DBUILD_TIFF:BOOL=OFF -DBUILD_USE_SYMLINKS:BOOL=OFF -DBUILD_WEBP:BOOL=OFF -DBUILD_WITH_DEBUG_INFO:BOOL=OFF -DBUILD_WITH_DYNAMIC_IPP:BOOL=OFF -DBUILD_ZLIB:BOOL=ON -DWITH_1394:BOOL=OFF -DWITH_ADE:BOOL=OFF -DWITH_ARAVIS:BOOL=OFF -DWITH_CLP:BOOL=OFF -DWITH_CUDA:BOOL=OFF -DWITH_EIGEN:BOOL=OFF -DWITH_FFMPEG:BOOL=OFF -DWITH_FREETYPE:BOOL=OFF -DWITH_GDAL:BOOL=OFF -DWITH_GDCM:BOOL=OFF -DWITH_GPHOTO2:BOOL=OFF -DWITH_GSTREAMER:BOOL=OFF -DWITH_GTK:BOOL=OFF -DWITH_GTK_2_X:BOOL=OFF -DWITH_HALIDE:BOOL=OFF -DWITH_HPX:BOOL=OFF -DWITH_IMGCODEC_HDR:BOOL=OFF -DWITH_IMGCODEC_PFM:BOOL=OFF -DWITH_IMGCODEC_PXM:BOOL=OFF -DWITH_IMGCODEC_SUNRASTER:BOOL=OFF -DWITH_INF_ENGINE:BOOL=OFF -DWITH_IPP:BOOL=OFF -DWITH_ITT:BOOL=OFF -DWITH_JASPER:BOOL=OFF -DWITH_JPEG:BOOL=OFF -DWITH_LAPACK:BOOL=OFF -DWITH_LIBREALSENSE:BOOL=OFF -DWITH_MFX:BOOL=OFF -DWITH_NGRAPH:BOOL=OFF -DWITH_OPENCL:BOOL=OFF -DWITH_OPENCLAMDBLAS:BOOL=OFF -DWITH_OPENCLAMDFFT:BOOL=OFF -DWITH_OPENCL_SVM:BOOL=OFF -DWITH_OPENEXR:BOOL=OFF -DWITH_OPENGL:BOOL=OFF -DWITH_OPENJPEG:BOOL=OFF -DWITH_OPENMP:BOOL=OFF -DWITH_OPENNI:BOOL=OFF -DWITH_OPENNI2:BOOL=OFF -DWITH_OPENVX:BOOL=OFF -DWITH_PLAIDML:BOOL=OFF -DWITH_PNG:BOOL=OFF -DWITH_PROTOBUF:BOOL=OFF -DWITH_PTHREADS_PF:BOOL=OFF -DWITH_PVAPI:BOOL=OFF -DWITH_QT:BOOL=OFF -DWITH_QUIRC:BOOL=OFF -DWITH_TBB:BOOL=OFF -DWITH_TIFF:BOOL=OFF -DWITH_V4L:BOOL=OFF -DWITH_VA:BOOL=OFF -DWITH_VA_INTEL:BOOL=OFF -DWITH_VTK:BOOL=OFF -DWITH_VULKAN:BOOL=OFF -DWITH_WEBP:BOOL=OFF -DWITH_XIMEA:BOOL=OFF -DWITH_XINE:BOOL=OFF  ..
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
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TOOLS=OFF -DEXPAT_SHARED_LIBS=OFF -DEXPAT_BUILD_TESTS:BOOL=OFF ../expat
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
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DENABLE_SPATIAL=ON -DWITH_CPP_NAMESPACE=ON -DLIBSBML_SKIP_SHARED_LIBRARY=ON -DWITH_BZIP2=OFF -DWITH_ZLIB=OFF -DWITH_SWIG=OFF -DWITH_LIBXML=OFF -DWITH_EXPAT=ON -DLIBEXPAT_INCLUDE_DIR=$INSTALL_PREFIX/include -DLIBEXPAT_LIBRARY=$INSTALL_PREFIX/lib/libexpat.a ..
time make -j$NPROCS
$SUDOCMD make install
cd ../../

# build static version of fmt
git clone -b $FMT_VERSION --depth 1 https://github.com/fmtlib/fmt.git
cd fmt
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_CXX_STANDARD=17 -DFMT_DOC=OFF -DFMT_TEST:BOOL=OFF ..
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of libTIFF
git clone -b $LIBTIFF_VERSION --depth 1 https://gitlab.com/libtiff/libtiff.git
cd libtiff
mkdir cmake-build
cd cmake-build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -Djpeg=OFF -Djpeg12=OFF -Djbig=OFF -Dlzma=OFF -Dpixarlog=OFF -Dold-jpeg=OFF -Dzstd=OFF -Dmdi=OFF -Dwebp=OFF -Dzlib=OFF -DGLUT_INCLUDE_DIR=GLUT_INCLUDE_DIR-NOTFOUND -DOPENGL_INCLUDE_DIR=OPENGL_INCLUDE_DIR-NOTFOUND ..
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of muparser
git clone -b $MUPARSER_VERSION --depth 1 https://github.com/beltoforion/muparser.git
cd muparser
mkdir cmake-build
cd cmake-build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_TESTING=OFF -DENABLE_OPENMP=OFF -DENABLE_SAMPLES=OFF ..
time make -j$NPROCS
#make test
$SUDOCMD make install
cd ../../

# build static version of spdlog
git clone -b $SPDLOG_VERSION --depth 1 https://github.com/gabime/spdlog.git
cd spdlog
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DSPDLOG_BUILD_TESTS=OFF -DSPDLOG_BUILD_EXAMPLE=OFF -DSPDLOG_FMT_EXTERNAL=ON -DSPDLOG_NO_THREAD_ID=ON -DSPDLOG_NO_ATOMIC_LEVELS=ON -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX -DSPDLOG_BUILD_TESTS=OFF ..
time make -j$NPROCS
#make test
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
#time make check
$SUDOCMD make install
cd ..

# build static version of symengine
git clone -b $SYMENGINE_VERSION --depth 1 https://github.com/symengine/symengine.git
cd symengine
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.12" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_CXX_FLAGS="-fpic -fvisibility=hidden" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_BENCHMARKS=OFF -DGMP_INCLUDE_DIR=$INSTALL_PREFIX/include -DGMP_LIBRARY=$INSTALL_PREFIX/lib/libgmp.a -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX -DWITH_LLVM=ON -DWITH_COTIRE=OFF -DWITH_SYMENGINE_THREAD_SAFE=OFF -DBUILD_TESTS=OFF -DWITH_CPP14=ON ..
time make -j$NPROCS
#time make test
$SUDOCMD make install
cd ../../
