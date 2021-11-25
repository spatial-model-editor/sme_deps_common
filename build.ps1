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

mkdir ${Env:INSTALL_PREFIX}/include
mkdir ${Env:INSTALL_PREFIX}/lib

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
cp zlibstatic.lib ${Env:INSTALL_PREFIX}/lib/.
cp zconf.h ${Env:INSTALL_PREFIX}/include/.
cp ../zlib.h ${Env:INSTALL_PREFIX}/include/.
cd ../../


# build static version of expat xml library
git clone -b $env:LIBEXPAT_VERSION --depth 1 https://github.com/libexpat/libexpat.git
cd libexpat
mkdir build
cd build
cmake -G "Ninja" ../expat `
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.14" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX" `
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
git clone -b $env:LIBSBML_VERSION --depth 1 https://github.com/sbmlteam/libsbml.git
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
  -DLIBSBML_SKIP_SHARED_LIBRARY=ON `
  -DWITH_BZIP2=OFF `
  -DWITH_ZLIB=ON `
  -DLIBZ_INCLUDE_DIR="${Env:INSTALL_PREFIX}/include" `
  -DLIBZ_LIBRARY="${Env:INSTALL_PREFIX}/lib/zlibstatic.lib" `
  -DWITH_SWIG=OFF `
  -DWITH_LIBXML=OFF `
  -DWITH_EXPAT=ON `
  -DLIBEXPAT_INCLUDE_DIR="${env:INSTALL_PREFIX}\include" `
  -DLIBEXPAT_LIBRARY="${env:INSTALL_PREFIX}\lib\libexpatMD.lib"
cmake --build . --parallel
cmake --install .
cd ..\..
