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
ctest
cmake --install .

git clone -b ${Env:TBB_VERSION} --depth 1 https://github.com/intel/tbb.git
cd tbb
gmake.exe tbb ${Env:TBB_OPTIONS} stdver=c++17 extra_inc=big_iron.inc
ls *\*
# time make tbb $TBB_OPTIONS stdver=c++17 extra_inc=big_iron.inc -j$NPROCS
# ls build/*_release
# $SUDOCMD mkdir -p $INSTALL_PREFIX/lib
# $SUDOCMD cp build/*_release/*.a $INSTALL_PREFIX/lib
# $SUDOCMD mkdir -p $INSTALL_PREFIX/include
# $SUDOCMD cp -r include/tbb $INSTALL_PREFIX/include/.
# ls $INSTALL_PREFIX/*/*
# cd ../

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
  -DWITH_LLVM=OFF `
  -DWITH_COTIRE=OFF `
  -DWITH_SYMENGINE_THREAD_SAFE=OFF `
  -DBUILD_TESTS=OFF
cmake --build . --parallel
ctest
cmake --install .
cd ..\..

mkdir artefacts
cd artefacts
7z a tmp.tar $Env:INSTALL_PREFIX
7z a sme_deps_llvm_$Env:OS_TARGET.tgz tmp.tar
rm tmp.tar