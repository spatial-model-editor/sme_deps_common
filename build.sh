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
echo "INSTALL_PREFIX: ${INSTALL_PREFIX}"
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
echo "CUDA_REDIST_VERSION: ${CUDA_REDIST_VERSION}"

NPROCS=$(getconf _NPROCESSORS_ONLN)
echo "BUILD_TAG = $BUILD_TAG"
echo "NPROCS: ${NPROCS}"
echo "PATH: ${PATH}"
echo "SUDO_CMD: ${SUDO_CMD}"

SANITIZER_FLAGS=""
if [[ ${BUILD_TAG} == "_tsan" ]]; then
    SANITIZER_FLAGS="-fsanitize=thread"
fi

# configure a static release build of the cmake project in the given source dir with ccache, to be installed in INSTALL_PREFIX
# (on macOS cmake uses the MACOSX_DEPLOYMENT_TARGET env var to set CMAKE_OSX_DEPLOYMENT_TARGET)
cmake_configure() {
    local source_dir=$1
    shift
    cmake -GNinja "${source_dir}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_C_VISIBILITY_PRESET=hidden \
        -DCMAKE_CXX_VISIBILITY_PRESET=hidden \
        -DCMAKE_C_FLAGS="${SANITIZER_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${SANITIZER_FLAGS}" \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
        -DCMAKE_PREFIX_PATH="${INSTALL_PREFIX}" \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        "$@"
}
which make
make --version
which python
python --version
which cmake
cmake --version

download_and_extract_cuda_component() {
    local component=$1
    local platform=$2
    local archive="${component}-${platform}-${CUDA_REDIST_VERSION}-archive.tar.xz"
    local url="https://developer.download.nvidia.com/compute/cuda/redist/${component}/${platform}/${archive}"

    wget -q "${url}"
    tar -xf "${archive}"
}

copy_cuda_tree() {
    local src_root=$1
    local dst_root=$2

    if [[ -d "${src_root}/include" ]]; then
        mkdir -p "${dst_root}/include"
        cp -a "${src_root}/include/." "${dst_root}/include/"
    fi
    if [[ -d "${src_root}/lib" ]]; then
        mkdir -p "${dst_root}/lib"
        cp -a "${src_root}/lib/." "${dst_root}/lib/"
    fi
}

patch_cuda_static_archives() {
    local cuda_target_dir=$1
    local static_lib=""

    # Work around lld crashes on CUDA static archives, see:
    # https://forums.developer.nvidia.com/t/bug-libnvptxcompiler-static-a-segfaults-when-linked-with-lld-on-x86-64/359281/2
    while IFS= read -r -d '' static_lib; do
        llvm-objcopy \
            --rename-section .ctors=.init_array \
            --rename-section .dtors=.fini_array \
            "${static_lib}"
    done < <(find "${cuda_target_dir}" -type f -name '*_static.a' -print0)
}

install_cuda_bundle() {
    local cuda_platform=""
    local cuda_target_dir=""
    local cuda_root="${INSTALL_PREFIX}/cuda"

    case "${OS}" in
    linux)
        cuda_platform="linux-x86_64"
        cuda_target_dir="${cuda_root}/targets/x86_64-linux"
        ;;
    linux-arm64)
        cuda_platform="linux-sbsa"
        cuda_target_dir="${cuda_root}/targets/sbsa-linux"
        ;;
    *)
        echo "Skipping CUDA bundle for ${OS}"
        return 0
        ;;
    esac

    rm -rf "${cuda_root}"
    mkdir -p "${cuda_target_dir}"
    cat >"${cuda_root}/version.json" <<EOF
{
  "cuda": {
    "name": "CUDA Toolkit",
    "version": "${CUDA_REDIST_VERSION}"
  }
}
EOF

    download_and_extract_cuda_component "cuda_cudart" "${cuda_platform}"
    download_and_extract_cuda_component "cuda_crt" "${cuda_platform}"
    download_and_extract_cuda_component "cuda_nvrtc" "${cuda_platform}"
    download_and_extract_cuda_component "libnvptxcompiler" "${cuda_platform}"

    copy_cuda_tree "cuda_cudart-${cuda_platform}-${CUDA_REDIST_VERSION}-archive" "${cuda_target_dir}"
    copy_cuda_tree "cuda_crt-${cuda_platform}-${CUDA_REDIST_VERSION}-archive" "${cuda_target_dir}"
    copy_cuda_tree "cuda_nvrtc-${cuda_platform}-${CUDA_REDIST_VERSION}-archive" "${cuda_target_dir}"
    copy_cuda_tree "libnvptxcompiler-${cuda_platform}-${CUDA_REDIST_VERSION}-archive" "${cuda_target_dir}"

    patch_cuda_static_archives "${cuda_target_dir}"
}

# build static version of nlopt (required by pagmo)
git clone -b $NLOPT_VERSION --depth 1 https://github.com/stevengj/nlopt.git
cd nlopt
mkdir build
cd build
cmake_configure .. \
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
cmake_configure .. \
    -DBUILD_TESTING=OFF
${SUDO_CMD} ninja install
cd ../../

# build static version of bzip2
git clone -b ${BZIP2_VERSION} --depth 1 https://gitlab.com/bzip2/bzip2.git
cd bzip2
# copy of existing cflags from Makefile with additional -fPIC and optional sanitizer
BZIP2_CFLAGS="-O2 -g -D_FILE_OFFSET_BITS=64 -fPIC${SANITIZER_FLAGS:+ ${SANITIZER_FLAGS}}"
# also specify CC if CC env var is set
if [ -z "$CC" ]; then make "CFLAGS=${BZIP2_CFLAGS}" -j${NPROCS}; else make CC=${CC} "CFLAGS=${BZIP2_CFLAGS}" -j${NPROCS}; fi
make install PREFIX="$INSTALL_PREFIX"
cd ../

# install Cereal headers
git clone -b $CEREAL_VERSION --depth 1 https://github.com/USCiLab/cereal.git
cd cereal
mkdir build
cd build
cmake_configure .. \
    -DJUST_INSTALL_CEREAL=ON
${SUDO_CMD} ninja install
cd ../../

# build static version of QCustomPlot (using our own cmakelists)
wget https://www.qcustomplot.com/release/${QCUSTOMPLOT_VERSION}/QCustomPlot-source.tar.gz
tar xf QCustomPlot-source.tar.gz
cp qcustomplot-source/* qcustomplot/.
git apply --ignore-space-change --ignore-whitespace --verbose qcustomplot.diff
cd qcustomplot
mkdir build
cd build
cmake_configure .. \
    -DZLIB_INCLUDE_DIR=${INSTALL_PREFIX}/include \
    -DZLIB_LIBRARY_RELEASE=${INSTALL_PREFIX}/lib/libz.a \
    -DWITH_QT6=ON
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of boost & install headers
# (boost release archives can't be built with cmake, so use the cmake-specific archive from github)
wget https://github.com/boostorg/boost/releases/download/boost-${BOOST_VERSION}/boost-${BOOST_VERSION}-cmake.tar.gz
tar xf boost-${BOOST_VERSION}-cmake.tar.gz
cd boost-${BOOST_VERSION}
mkdir build
cd build
# install all libraries except for these compiled ones that we don't need
cmake_configure .. \
    -DBOOST_EXCLUDE_LIBRARIES="cobalt;contract;coroutine;fiber;iostreams;json;locale;log;nowide;process;program_options;test;timer;url;wave"
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of Google Benchmark library
git clone -b $BENCHMARK_VERSION --depth 1 https://github.com/google/benchmark.git
cd benchmark
mkdir build
cd build
cmake_configure .. \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DBENCHMARK_ENABLE_TESTING=OFF
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of Catch2 library
# build with posix signals disabled to avoid https://github.com/catchorg/Catch2/issues/1833 when using TSAN
git clone -b $CATCH2_VERSION --depth 1 https://github.com/catchorg/Catch2.git
cd Catch2
mkdir build
cd build
cmake_configure .. \
    -DCATCH_INSTALL_DOCS=OFF \
    -DCATCH_CONFIG_NO_POSIX_SIGNALS=1 \
    -DCATCH_INSTALL_EXTRAS=ON
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of opencv library
git clone -b $OPENCV_VERSION --depth 1 https://github.com/opencv/opencv.git
cd opencv
mkdir build
cd build
cmake_configure .. \
    -DBUILD_LIST=core,imgproc \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_ZLIB=OFF \
    -DWITH_EIGEN=OFF \
    -DWITH_IPP=OFF \
    -DWITH_ITT=OFF \
    -DWITH_KLEIDICV=OFF \
    -DWITH_LAPACK=OFF \
    -DWITH_OPENCL=OFF \
    -DWITH_PTHREADS_PF=OFF \
    -DWITH_VA=OFF \
    -DWITH_VA_INTEL=OFF \
    -DWITH_JASPER=OFF \
    -DWITH_JPEG=OFF \
    -DWITH_OPENEXR=OFF \
    -DWITH_OPENJPEG=OFF \
    -DWITH_PNG=OFF \
    -DWITH_PROTOBUF=OFF \
    -DWITH_TIFF=OFF \
    -DWITH_WEBP=OFF \
    -DZLIB_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DZLIB_LIBRARY_RELEASE=$INSTALL_PREFIX/lib/libz.a
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of oneTBB
git clone -b $TBB_VERSION --depth 1 https://github.com/uxlfoundation/oneTBB.git
cd oneTBB
mkdir build
cd build
cmake_configure .. \
    -DTBB_STRICT=OFF \
    -DTBB_TEST=OFF
time ninja tbb
${SUDO_CMD} ninja install
cd ../../

# build static version of oneDPL
git clone -b $DPL_VERSION --depth 1 https://github.com/uxlfoundation/oneDPL
cd oneDPL
mkdir build
cd build
cmake_configure .. \
    -DONEDPL_BACKEND="tbb"
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of pagmo
git clone -b $PAGMO_VERSION --depth 1 https://github.com/esa/pagmo2.git
cd pagmo2
mkdir build
cd build
cmake_configure .. \
    -DPAGMO_BUILD_STATIC_LIBRARY=ON \
    -DPAGMO_WITH_NLOPT=ON \
    -DPAGMO_BUILD_TESTS=OFF
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of expat xml library
git clone -b $LIBEXPAT_VERSION --depth 1 https://github.com/libexpat/libexpat.git
cd libexpat
mkdir build
cd build
cmake_configure ../expat \
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
mkdir build
cd build
cmake_configure .. \
    -DENABLE_SPATIAL=ON \
    -DWITH_CPP_NAMESPACE=ON \
    -DWITH_THREADSAFE_PARSER=ON \
    -DLIBSBML_SKIP_SHARED_LIBRARY=ON \
    -DWITH_BZIP2=ON \
    -DLIBBZ_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DLIBBZ_LIBRARY=$INSTALL_PREFIX/lib/libbz2.a \
    -DWITH_ZLIB=ON \
    -DZLIB_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DZLIB_LIBRARY=$INSTALL_PREFIX/lib/libz.a \
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
cmake_configure .. \
    -DLIBCOMBINE_SKIP_SHARED_LIBRARY=ON \
    -DWITH_CPP_NAMESPACE=ON \
    -DEXTRA_LIBS="$INSTALL_PREFIX/lib/libz.a;$INSTALL_PREFIX/lib/libbz2.a;$INSTALL_PREFIX/lib/libexpat.a" \
    -DZLIB_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DZLIB_LIBRARY=$INSTALL_PREFIX/lib/libz.a
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of fmt
git clone -b $FMT_VERSION --depth 1 https://github.com/fmtlib/fmt.git
cd fmt
mkdir build
cd build
cmake_configure .. \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_DOC=OFF \
    -DFMT_TEST:BOOL=OFF
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of libTIFF
git clone -b $LIBTIFF_VERSION --depth 1 https://gitlab.com/libtiff/libtiff.git
cd libtiff
# note libtiff cmake install is broken for all dependencies, so for now we just disable them all
mkdir cmake-build
cd cmake-build
cmake_configure .. \
    -Dtiff-tools=OFF \
    -Dtiff-tests=OFF \
    -Dtiff-contrib=OFF \
    -Dtiff-docs=OFF \
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
cmake_configure .. \
    -DCMAKE_CXX_STANDARD=20 \
    -DSPDLOG_BUILD_TESTS=OFF \
    -DSPDLOG_BUILD_EXAMPLE=OFF \
    -DSPDLOG_FMT_EXTERNAL=ON \
    -DSPDLOG_NO_THREAD_ID=ON \
    -DSPDLOG_NO_ATOMIC_LEVELS=ON
time ninja
${SUDO_CMD} ninja install
cd ../../

# build static version of gmp
# temporary workaround for gmp blacklisting github ips:
# wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz
wget https://github.com/spatial-model-editor/spatial-model-editor.github.io/releases/download/1.0.0/gmp-${GMP_VERSION}.tar.xz
tar xf gmp-${GMP_VERSION}.tar.xz
cd gmp-${GMP_VERSION}
# note: includes this patch for configure error with gcc15 as it defaults to c23 (from https://gitlab.archlinux.org/archlinux/packaging/packages/gmp/-/blob/main/gmp-gcc-15.patch?ref_type=heads)
# (the following two commands were ran on the files hosted above)
### git apply --ignore-space-change --ignore-whitespace --verbose ../gmp.diff
### autoreconf -i -f
CFLAGS="${SANITIZER_FLAGS}" \
    CXXFLAGS="${SANITIZER_FLAGS}" \
    LDFLAGS="${SANITIZER_FLAGS}" \
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
tar xf mpfr-${MPFR_VERSION}.tar.xz
cd mpfr-${MPFR_VERSION}
CFLAGS="${SANITIZER_FLAGS}" \
    CXXFLAGS="${SANITIZER_FLAGS}" \
    LDFLAGS="${SANITIZER_FLAGS}" \
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
cmake_configure .. \
    -DWITH_CGAL_ImageIO=OFF
${SUDO_CMD} ninja install
cd ../../

# build static version of symengine
git clone -b $SYMENGINE_VERSION --depth 1 https://github.com/symengine/symengine.git
cd symengine
mkdir build
cd build
cmake_configure .. \
    -DBUILD_BENCHMARKS=OFF \
    -DGMP_INCLUDE_DIR=$INSTALL_PREFIX/include \
    -DGMP_LIBRARY=$INSTALL_PREFIX/lib/libgmp.a \
    -DWITH_LLVM=ON \
    -DWITH_SYSTEM_CEREAL=ON \
    -DWITH_SYMENGINE_THREAD_SAFE=ON \
    -DBUILD_TESTS=OFF
time ninja
${SUDO_CMD} ninja install
cd ../../

# combine the static libs implicitly required by qt's bundled freetype lib into a single .a lib for vtk to use
# (on linux vtk uses the system freetype, on windows this is done in build.ps1)
if [ "$RUNNER_OS" == "macOS" ]; then
    libtool -static -o ${INSTALL_PREFIX}/lib/libCombinedFreetype.a ${INSTALL_PREFIX}/lib/libQt6BundledFreetype.a ${INSTALL_PREFIX}/lib/libQt6BundledLibpng.a ${INSTALL_PREFIX}/lib/libz.a
    VTK_OPTIONS="-DFREETYPE_LIBRARY_RELEASE=${INSTALL_PREFIX}/lib/libCombinedFreetype.a -DFREETYPE_INCLUDE_DIR_freetype2=${INSTALL_PREFIX}/include/QtFreetype -DFREETYPE_INCLUDE_DIR_ft2build=${INSTALL_PREFIX}/include/QtFreetype"
fi

# build minimal static version of VTK including GUISupportQt and RenderingQt modules
git clone -b $VTK_VERSION --depth 1 https://gitlab.kitware.com/vtk/vtk.git VTK
cd VTK
git apply --ignore-space-change --ignore-whitespace --verbose ../vtk.diff
mkdir build
cd build
cmake_configure .. \
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
    -DVTK_USE_PCH=OFF \
    ${VTK_OPTIONS}
time ninja
${SUDO_CMD} ninja install
cd ../../

# Scotch (includes METIS compatibility library)
git clone -b $SCOTCH_VERSION --depth 1 https://gitlab.inria.fr/scotch/scotch.git
cd scotch
mkdir build
cd build
cmake_configure .. \
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

install_cuda_bundle

if [ "$OS" = "osx-arm64" ]; then
    git clone -b release/metal-cpp_${METALCPP_VERSION} --depth 1 https://github.com/apple/metal-cpp.git
    rm -rf metal-cpp/.git
    ${SUDO_CMD} cp -R metal-cpp "${INSTALL_PREFIX}/"
fi

ccache --show-stats

mkdir artefacts
cd artefacts
tar -zcvf sme_deps_common_${OS}${BUILD_TAG}.tgz $INSTALL_PREFIX/*
