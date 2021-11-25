echo "HOST_TRIPLE: $Env:HOST_TRIPLE"
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
echo "TBB_OPTIONS: $Env:TBB_OPTIONS"
echo "OPENCV_VERSION: $Env:OPENCV_VERSION"
echo "CATCH2_VERSION: $Env:CATCH2_VERSION"
echo "BENCHMARK_VERSION: $Env:BENCHMARK_VERSION"
echo "CGAL_VERSION: $Env:CGAL_VERSION"
echo "BOOST_VERSION: $Env:BOOST_VERSION"
echo "BOOST_VERSION_: $Env:BOOST_VERSION_"
echo "QCUSTOMPLOT_VERSION: $Env:QCUSTOMPLOT_VERSION"
echo "CEREAL_VERSION: $Env:CEREAL_VERSION"
echo "ZLIB_VERSION: $Env:ZLIB_VERSION"

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
ls
ls *\*

# manual install to avoid shared libs being installed & issues with compiling example programs
# wildcard is used because on mingw it calls the library file libzlibstatic.a for some reason:
#cp libz*.a $INSTALL_PREFIX/lib/libz.a
#cp zconf.h $INSTALL_PREFIX/include/.
#cp ../zlib.h $INSTALL_PREFIX/include/.
cd ../../
