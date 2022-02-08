echo "LLVM_VERSION: $Env:LLVM_VERSION"
echo "QT_VERSION: $Env:QT_VERSION"
echo "LIBSBML_VERSION: $Env:LIBSBML_VERSION"
echo "LIBEXPAT_VERSION: $Env:LIBEXPAT_VERSION"
echo "SYMENGINE_VERSION: $Env:SYMENGINE_VERSION"
echo "GMP_VERSION: $Env:GMP_VERSION"
echo "MPFR_VERSION: $Env:MPFR_VERSION"
echo "SPDLOG_VERSION: $Env:SPDLOG_VERSION"
echo "MUSPARSER_VERSION: $Env:MUPARSER_VERSION"
echo "LIBTIFF_VERSION: $Env:LIBTIFF_VERSION"
echo "FMT_VERSION: $Env:FMT_VERSION"
echo "TBB_VERSION: $Env:TBB_VERSION"
echo "TBB_EXTRA_FLAGS: $Env:TBB_EXTRA_FLAGS"
echo "OPENCV_VERSION: $Env:OPENCV_VERSION"
echo "CATCH2_VERSION: $Env:CATCH2_VERSION"
echo "BENCHMARK_VERSION: $Env:BENCHMARK_VERSION"
echo "CGAL_VERSION: $Env:CGAL_VERSION"
echo "BOOST_VERSION: $Env:BOOST_VERSION"
echo "BOOST_VERSION_: $Env:BOOST_VERSION_"
echo "QCUSTOMPLOT_VERSION: $Env:QCUSTOMPLOT_VERSION"
echo "CEREAL_VERSION: $Env:CEREAL_VERSION"
echo "ZLIB_VERSION: $Env:ZLIB_VERSION"

echo "downloading qt & llvm for OS_TARGET: $OS_TARGET"
# download llvm static libs
$client = New-Object System.Net.WebClient
$client.DownloadFile("https://github.com/spatial-model-editor/sme_deps_llvm/releases/download/$Env:LLVM_VERSION/sme_deps_llvm_$Env:OS_TARGET.tgz", "C:\llvm.tgz")
7z e C:\llvm.tgz
7z x tmp.tar
rm tmp.tar

# download qt static libs
$client.DownloadFile("https://github.com/spatial-model-editor/sme_deps_qt/releases/download/$Env:QT_VERSION/sme_deps_qt_$Env:OS_TARGET.tgz", "C:\qt.tgz")
7z e C:\qt.tgz
7z x tmp.tar
rm tmp.tar

ls
mv smelibs C:\
ls C:\smelibs


# build static version of zlib
git clone -b ${Env:ZLIB_VERSION} --depth 1 https://github.com/madler/zlib.git
cd zlib
mkdir build
cd build
cmake -G "Ninja" .. `
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
    -DCMAKE_BUILD_TYPE=Release `
    -DBUILD_SHARED_LIBS=OFF `
    -DCMAKE_INSTALL_PREFIX="${Env:INSTALL_PREFIX}"
cmake --build . --parallel
# manual install to avoid shared libs being installed & issues with compiling example programs
cp zlibstatic.lib ${Env:INSTALL_PREFIX}/lib/.
cp zconf.h ${Env:INSTALL_PREFIX}/include/.
cp ../zlib.h ${Env:INSTALL_PREFIX}/include/.
cd ../../

# install Cereal headers
git clone -b $Env:CEREAL_VERSION --depth 1 https://github.com/USCiLab/cereal.git
cd cereal
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_INSTALL_PREFIX="${Env:INSTALL_PREFIX}" `
  -DJUST_INSTALL_CEREAL=ON
cmake --install .
cd ..\..

# build static version of QCustomPlot (using our own cmakelists)
$client.DownloadFile("https://www.qcustomplot.com/release/$Env:QCUSTOMPLOT_VERSION/QCustomPlot-source.tar.gz", "C:\qcustomplot.tgz")
7z e C:\qcustomplot.tgz
7z x qcustomplot.tar
rm qcustomplot.tar
cp qcustomplot-source/* qcustomplot/.
cd qcustomplot
git apply --ignore-space-change --ignore-whitespace --verbose patch-6.2.diff
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="${Env:INSTALL_PREFIX}" `
  -DWITH_QT6=ON
cmake --build . --parallel
cmake --install .
cd ..\..

# build static version of boost serialization & install headers
$client.DownloadFile("https://boostorg.jfrog.io/artifactory/main/release/$Env:BOOST_VERSION/source/boost_$Env:BOOST_VERSION_.tar.gz", "C:\boost.tgz")
7z e C:\boost.tgz
7z x boost.tar
rm boost.tar
cd boost_${Env:BOOST_VERSION_}
.\bootstrap.bat --help
.\bootstrap.bat
.\b2 --help
.\b2 --prefix="${Env:INSTALL_PREFIX}" --with-serialization ${Env:BOOST_OPTIONS} link=static install
cd ..

# build static version of Google Benchmark library
git clone -b ${Env:BENCHMARK_VERSION} --depth 1 https://github.com/google/benchmark.git
cd benchmark
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="${Env:INSTALL_PREFIX}" `
  -DBENCHMARK_ENABLE_TESTING=OFF
cmake --build . --parallel
#make test
cmake --install .
cd ..\..

# build static version of Catch2 library
git clone -b $Env:CATCH2_VERSION --depth 1 https://github.com/catchorg/Catch2.git
cd Catch2
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="${Env:INSTALL_PREFIX}" `
  -DBUILD_SHARED_LIBS=OFF `
  -DCATCH_INSTALL_DOCS=OFF `
  -DCATCH_INSTALL_EXTRAS=ON
cmake --build . --parallel
#make test
cmake --install .
cd ..\..

# build static version of opencv library
git clone -b $Env:OPENCV_VERSION --depth 1 https://github.com/opencv/opencv.git
cd opencv
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="$Env:INSTALL_PREFIX" `
  -DBUILD_opencv_apps=OFF `
  -DBUILD_opencv_calib3d=OFF `
  -DBUILD_opencv_core=ON `
  -DBUILD_opencv_dnn=OFF `
  -DBUILD_opencv_features2d=OFF `
  -DBUILD_opencv_flann=OFF `
  -DBUILD_opencv_gapi=OFF `
  -DBUILD_opencv_highgui=OFF `
  -DBUILD_opencv_imgcodecs=OFF `
  -DBUILD_opencv_imgproc=ON `
  -DBUILD_opencv_java_bindings_generator=OFF `
  -DBUILD_opencv_js=OFF `
  -DBUILD_opencv_ml=OFF `
  -DBUILD_opencv_objdetect=OFF `
  -DBUILD_opencv_photo=OFF `
  -DBUILD_opencv_python_bindings_generator=OFF `
  -DBUILD_opencv_python_tests=OFF `
  -DBUILD_opencv_stitching=OFF `
  -DBUILD_opencv_ts=OFF `
  -DBUILD_opencv_video=OFF `
  -DBUILD_opencv_videoio=OFF `
  -DBUILD_opencv_world=OFF `
  -DBUILD_CUDA_STUBS:BOOL=OFF `
  -DBUILD_DOCS:BOOL=OFF `
  -DBUILD_EXAMPLES:BOOL=OFF `
  -DBUILD_FAT_JAVA_LIB:BOOL=OFF `
  -DBUILD_IPP_IW:BOOL=OFF `
  -DBUILD_ITT:BOOL=OFF `
  -DBUILD_JASPER:BOOL=OFF `
  -DBUILD_JAVA:BOOL=OFF `
  -DBUILD_JPEG:BOOL=OFF `
  -DBUILD_OPENEXR:BOOL=OFF `
  -DBUILD_PACKAGE:BOOL=OFF `
  -DBUILD_PERF_TESTS:BOOL=OFF `
  -DBUILD_PNG:BOOL=OFF `
  -DBUILD_PROTOBUF:BOOL=OFF `
  -DBUILD_SHARED_LIBS:BOOL=OFF `
  -DBUILD_TBB:BOOL=OFF `
  -DBUILD_TESTS:BOOL=OFF `
  -DBUILD_TIFF:BOOL=OFF `
  -DBUILD_USE_SYMLINKS:BOOL=OFF `
  -DBUILD_WEBP:BOOL=OFF `
  -DBUILD_WITH_DEBUG_INFO:BOOL=OFF `
  -DBUILD_WITH_DYNAMIC_IPP:BOOL=OFF `
  -DBUILD_ZLIB:BOOL=OFF `
  -DWITH_1394:BOOL=OFF `
  -DWITH_ADE:BOOL=OFF `
  -DWITH_ARAVIS:BOOL=OFF `
  -DWITH_CLP:BOOL=OFF `
  -DWITH_CUDA:BOOL=OFF `
  -DWITH_EIGEN:BOOL=OFF `
  -DWITH_FFMPEG:BOOL=OFF `
  -DWITH_FREETYPE:BOOL=OFF `
  -DWITH_GDAL:BOOL=OFF `
  -DWITH_GDCM:BOOL=OFF `
  -DWITH_GPHOTO2:BOOL=OFF `
  -DWITH_GSTREAMER:BOOL=OFF `
  -DWITH_GTK:BOOL=OFF `
  -DWITH_GTK_2_X:BOOL=OFF `
  -DWITH_HALIDE:BOOL=OFF `
  -DWITH_HPX:BOOL=OFF `
  -DWITH_IMGCODEC_HDR:BOOL=OFF `
  -DWITH_IMGCODEC_PFM:BOOL=OFF `
  -DWITH_IMGCODEC_PXM:BOOL=OFF `
  -DWITH_IMGCODEC_SUNRASTER:BOOL=OFF `
  -DWITH_INF_ENGINE:BOOL=OFF `
  -DWITH_IPP:BOOL=OFF `
  -DWITH_ITT:BOOL=OFF `
  -DWITH_JASPER:BOOL=OFF `
  -DWITH_JPEG:BOOL=OFF `
  -DWITH_LAPACK:BOOL=OFF `
  -DWITH_LIBREALSENSE:BOOL=OFF `
  -DWITH_MFX:BOOL=OFF `
  -DWITH_NGRAPH:BOOL=OFF `
  -DWITH_OPENCL:BOOL=OFF `
  -DWITH_OPENCLAMDBLAS:BOOL=OFF `
  -DWITH_OPENCLAMDFFT:BOOL=OFF `
  -DWITH_OPENCL_SVM:BOOL=OFF `
  -DWITH_OPENEXR:BOOL=OFF `
  -DWITH_OPENGL:BOOL=OFF `
  -DWITH_OPENJPEG:BOOL=OFF `
  -DWITH_OPENMP:BOOL=OFF `
  -DWITH_OPENNI:BOOL=OFF `
  -DWITH_OPENNI2:BOOL=OFF `
  -DWITH_OPENVX:BOOL=OFF `
  -DWITH_PLAIDML:BOOL=OFF `
  -DWITH_PNG:BOOL=OFF `
  -DWITH_PROTOBUF:BOOL=OFF `
  -DWITH_PTHREADS_PF:BOOL=OFF `
  -DWITH_PVAPI:BOOL=OFF `
  -DWITH_QT:BOOL=OFF `
  -DWITH_QUIRC:BOOL=OFF `
  -DWITH_TBB:BOOL=OFF `
  -DWITH_TIFF:BOOL=OFF `
  -DWITH_V4L:BOOL=OFF `
  -DWITH_VA:BOOL=OFF `
  -DWITH_VA_INTEL:BOOL=OFF `
  -DWITH_VTK:BOOL=OFF `
  -DWITH_VULKAN:BOOL=OFF `
  -DWITH_WEBP:BOOL=OFF `
  -DWITH_XIMEA:BOOL=OFF `
  -DWITH_XINE:BOOL=OFF `
  -DLIBZ_INCLUDE_DIR="${Env:INSTALL_PREFIX}\include" `
  -DZLIB_LIBRARY_RELEASE="${Env:INSTALL_PREFIX}\lib\zlibstatic.lib"
cmake --build . --parallel
#make test
cmake --install .
cd ..\..

# build static version of tbb
git clone -b ${Env:TBB_VERSION} --depth 1 https://github.com/intel/tbb.git
cd tbb
mkdir build
cd build
cmake -G "Ninja" .. `
    -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
    -DCMAKE_BUILD_TYPE=Release `
    -DBUILD_SHARED_LIBS=OFF `
    -DCMAKE_INSTALL_PREFIX="${Env:INSTALL_PREFIX}" `
    -DTBB_STRICT=OFF `
    -DTBB_TEST=OFF
cmake --build . --parallel
#ctest
cmake --install .
cd ..\..

# build static version of pagmo
git clone -b ${Env:PAGMO_VERSION} --depth 1 https://github.com/esa/pagmo2.git
cd pagmo2
mkdir build
cd build
cmake -G "Ninja" .. `
    -DCMAKE_BUILD_TYPE=Release `
    -DBUILD_SHARED_LIBS=OFF `
    -DCMAKE_INSTALL_PREFIX="${Env:INSTALL_PREFIX}" `
    -DCMAKE_PREFIX_PATH="${Env:INSTALL_PREFIX}" `
    -DPAGMO_BUILD_STATIC_LIBRARY=ON `
    -DPAGMO_BUILD_TESTS=OFF
cmake --build . --parallel
#ctest
cmake --install .
cd ..\..

# build static version of expat xml library
git clone -b $Env:LIBEXPAT_VERSION --depth 1 https://github.com/libexpat/libexpat.git
cd libexpat
mkdir build
cd build
cmake -G "Ninja" ../expat `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="$Env:INSTALL_PREFIX" `
  -DEXPAT_BUILD_DOCS=OFF `
  -DEXPAT_BUILD_EXAMPLES=OFF `
  -DEXPAT_BUILD_TOOLS=OFF `
  -DEXPAT_SHARED_LIBS=OFF `
  -DEXPAT_BUILD_TESTS:BOOL=OFF
cmake --build . --parallel
#make test
cmake --install .
cd ..\..

# build static version of libSBML including spatial extension
git clone -b $Env:LIBSBML_VERSION --depth 1 https://github.com/sbmlteam/libsbml.git
cd libsbml
git status
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="${env:INSTALL_PREFIX}" `
  -DENABLE_SPATIAL=ON `
  -DWITH_CPP_NAMESPACE=ON `
  -DWITH_THREADSAFE_PARSER=ON `
  -DLIBSBML_SKIP_SHARED_LIBRARY=ON `
  -DWITH_ZLIB=ON `
  -DLIBZ_INCLUDE_DIR="${Env:INSTALL_PREFIX}\include" `
  -DLIBZ_LIBRARY="${Env:INSTALL_PREFIX}\lib\zlibstatic.lib" `
  -DWITH_ZLIB=OFF `
  -DWITH_SWIG=OFF `
  -DWITH_LIBXML=OFF `
  -DWITH_EXPAT=ON `
  -DLIBEXPAT_INCLUDE_DIR="${env:INSTALL_PREFIX}\include" `
  -DLIBEXPAT_LIBRARY="${env:INSTALL_PREFIX}\lib\libexpatMD.lib"
cmake --build . --parallel
cmake --install .
cd ..\..

# build static version of fmt
git clone -b $Env:FMT_VERSION --depth 1 https://github.com/fmtlib/fmt.git
cd fmt
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="$Env:INSTALL_PREFIX" `
  -DCMAKE_CXX_STANDARD=17 `
  -DFMT_DOC=OFF `
  -DFMT_TEST:BOOL=OFF
cmake --build . --parallel
#make test
cmake --install .
cd ..\..

# build static version of libTIFF
git clone -b $Env:LIBTIFF_VERSION --depth 1 https://gitlab.com/libtiff/libtiff.git
cd libtiff
mkdir cmake-build
cd cmake-build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="$Env:INSTALL_PREFIX" `
  -Djpeg=OFF `
  -Djpeg12=OFF `
  -Djbig=OFF `
  -Dlzma=OFF `
  -Dlibdeflate=OFF `
  -Dpixarlog=OFF `
  -Dold-jpeg=OFF `
  -Dzstd=OFF `
  -Dmdi=OFF `
  -Dwebp=OFF `
  -Dzlib=OFF `
  -DGLUT_INCLUDE_DIR=GLUT_INCLUDE_DIR-NOTFOUND `
  -DOPENGL_INCLUDE_DIR=OPENGL_INCLUDE_DIR-NOTFOUND
cmake --build . --parallel
#make test
cmake --install .
cd ..\..

# build static version of muparser
git clone -b $Env:MUPARSER_VERSION --depth 1 https://github.com/beltoforion/muparser.git
cd muparser
mkdir cmake-build
cd cmake-build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="$Env:INSTALL_PREFIX" `
  -DBUILD_TESTING=OFF `
  -DENABLE_OPENMP=OFF `
  -DENABLE_SAMPLES=OFF
cmake --build . --parallel
#make test
cmake --install .
cd ..\..

# build static version of spdlog
git clone -b $Env:SPDLOG_VERSION --depth 1 https://github.com/gabime/spdlog.git
cd spdlog
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="$Env:INSTALL_PREFIX" `
  -DSPDLOG_BUILD_TESTS=OFF `
  -DSPDLOG_BUILD_EXAMPLE=OFF `
  -DSPDLOG_FMT_EXTERNAL=ON `
  -DSPDLOG_NO_THREAD_ID=ON `
  -DSPDLOG_NO_ATOMIC_LEVELS=ON `
  -DCMAKE_PREFIX_PATH=$Env:INSTALL_PREFIX
cmake --build . --parallel
#make test
cmake --install .
cd ..\..

# build static version of mpir
git clone --depth 1 https://github.com/BrianGladman/mpir.git
cd mpir\msvc\vs19
ls
msbuild.exe /p:Platform="${Env:PLAT}" /p:Configuration=Release lib_mpir_gc\lib_mpir_gc.vcxproj
msbuild.exe /p:Platform="${Env:PLAT}" /p:Configuration=Release lib_mpir_cxx\lib_mpir_cxx.vcxproj
ls ..\..\lib\${Env:PLAT}\Release\*
# copy headers & static libs
md -Force ${Env:INSTALL_PREFIX}\lib
md -Force ${Env:INSTALL_PREFIX}\include
cp ..\..\lib\${Env:PLAT}\Release\*.lib ${Env:INSTALL_PREFIX}\lib\.
cp ..\..\lib\${Env:PLAT}\Release\*.pdb ${Env:INSTALL_PREFIX}\lib\.
cp ..\..\lib\${Env:PLAT}\Release\*.h ${Env:INSTALL_PREFIX}\include\.
ls ${Env:INSTALL_PREFIX}\*\*
cd ..\..\..

# # build static version of mpfr
git clone --depth 1 https://github.com/BrianGladman/mpfr.git
cd mpfr\build.vs19
msbuild.exe /p:Platform="${Env:PLAT}" /p:Configuration=Release lib_mpfr\lib_mpfr.vcxproj
ls ..\lib\${Env:PLAT}\Release\*
ls lib\${Env:PLAT}\Release\*
cp lib\${Env:PLAT}\Release\*.lib ${Env:INSTALL_PREFIX}\lib\.
cp lib\${Env:PLAT}\Release\*.pdb ${Env:INSTALL_PREFIX}\lib\.
cp ..\lib\${Env:PLAT}\Release\*.h ${Env:INSTALL_PREFIX}\include\.
ls ${Env:INSTALL_PREFIX}\*\*
cd ..\..

# install CGAL (should just be copying headers)
git clone -b $Env:CGAL_VERSION --depth 1 https://github.com/CGAL/cgal.git
cd cgal
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="$Env:INSTALL_PREFIX" `
  -DWITH_CGAL_ImageIO=OFF `
  -DWITH_CGAL_Qt5=OFF
cmake --install .
cd ..\..

# build static version of symengine
git clone -b $Env:SYMENGINE_VERSION --depth 1 https://github.com/symengine/symengine.git
cd symengine
mkdir build
cd build
cmake -G "Ninja" .. `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="$Env:INSTALL_PREFIX" `
  -DBUILD_BENCHMARKS=OFF `
  -DGMP_INCLUDE_DIR="${Env:INSTALL_PREFIX}\include" `
  -DGMP_LIBRARY="${Env:INSTALL_PREFIX}\lib\mpir.lib" `
  -DCMAKE_PREFIX_PATH="${Env:INSTALL_PREFIX}" `
  -DWITH_LLVM=ON `
  -DWITH_COTIRE=OFF `
  -DWITH_SYMENGINE_THREAD_SAFE=ON `
  -DBUILD_TESTS=OFF
cmake --build . --parallel
ctest
cmake --install .
cd ..\..

mkdir artefacts
cd artefacts
7z a tmp.tar $Env:INSTALL_PREFIX
7z a sme_deps_common_$Env:OS_TARGET.tgz tmp.tar
rm tmp.tar
