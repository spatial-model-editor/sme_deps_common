Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($PSVersionTable.PSVersion.Major -ge 7) {
  $PSNativeCommandUseErrorActionPreference = $true
}

function New-Directory {
  param([Parameter(Mandatory)] [string]$Path)
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Download-File {
  param(
    [Parameter(Mandatory)] [string]$Url,
    [Parameter(Mandatory)] [string]$OutFile
  )

  Write-Host "Downloading $Url"
  $client = New-Object System.Net.WebClient
  $client.DownloadFile($Url, $OutFile)
}

function Invoke-GitClone {
  param(
    [Parameter(Mandatory)] [string]$Repository,
    [string]$Ref,
    [string]$Directory
  )

  $cloneArgs = @("clone", "--depth", "1")
  if ($Ref) {
    $cloneArgs += @("-b", $Ref)
  }
  $cloneArgs += $Repository
  if ($Directory) {
    $cloneArgs += $Directory
  }
  git @cloneArgs
}

function Invoke-GitClonePinnedCommit {
  param(
    [Parameter(Mandatory)] [string]$Repository,
    [Parameter(Mandatory)] [string]$Commit,
    [Parameter(Mandatory)] [string]$Directory
  )

  git init $Directory
  git -C $Directory remote add origin $Repository
  git -C $Directory fetch --depth 1 origin $Commit
  git -C $Directory checkout --detach FETCH_HEAD
}

function Invoke-CMakeConfigure {
  param([Parameter(Mandatory)] [string[]]$Arguments)

  $configureArgs = @($Arguments)
  if ($env:CMAKE_MSVC_RUNTIME_LIBRARY) {
    if (-not ($configureArgs | Where-Object { $_ -like "-DCMAKE_POLICY_DEFAULT_CMP0091=*" })) {
      # Older projects often keep CMP0091 at OLD, which makes them ignore
      # CMAKE_MSVC_RUNTIME_LIBRARY and silently fall back to /MD.
      $configureArgs += "-DCMAKE_POLICY_DEFAULT_CMP0091=NEW"
    }
  }
  if ($env:CMAKE_MSVC_RUNTIME_LIBRARY) {
    if (-not ($configureArgs | Where-Object { $_ -like "-DCMAKE_MSVC_RUNTIME_LIBRARY=*" })) {
      $configureArgs += "-DCMAKE_MSVC_RUNTIME_LIBRARY=$env:CMAKE_MSVC_RUNTIME_LIBRARY"
    }
  }
  if ($env:CMAKE_CXX_FLAGS) {
    if (-not ($configureArgs | Where-Object { $_ -like "-DCMAKE_CXX_FLAGS=*" })) {
      $configureArgs += "-DCMAKE_CXX_FLAGS=$env:CMAKE_CXX_FLAGS"
    }
  }
  if (Get-Command ccache -ErrorAction SilentlyContinue) {
    if (-not ($configureArgs | Where-Object { $_ -like "-DCMAKE_C_COMPILER_LAUNCHER=*" })) {
      $configureArgs += "-DCMAKE_C_COMPILER_LAUNCHER=ccache"
    }
    if (-not ($configureArgs | Where-Object { $_ -like "-DCMAKE_CXX_COMPILER_LAUNCHER=*" })) {
      $configureArgs += "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
    }
  }

  cmake @configureArgs
}

function Invoke-CMakeBuild {
  param([string[]]$Targets = @())
  if ($Targets.Count -gt 0) {
    cmake --build . --parallel --target @Targets
  } else {
    cmake --build . --parallel
  }
}

function Invoke-CMakeInstall {
  cmake --install .
}

function Add-ImportedTargetCompileDefinitions {
  param(
    [Parameter(Mandatory)] [string]$TargetsFile,
    [Parameter(Mandatory)] [string]$TargetName,
    [Parameter(Mandatory)] [string[]]$Definitions
  )

  if (-not (Test-Path $TargetsFile)) {
    throw "Could not find imported targets file: $TargetsFile"
  }

  $targetsContents = Get-Content -Path $TargetsFile -Raw
  if ($targetsContents -like "*set_property(TARGET $TargetName APPEND PROPERTY*") {
    return
  }

  $definitionList = ($Definitions | ForEach-Object { '"{0}"' -f $_ }) -join " "
  $patch = "`nset_property(TARGET $TargetName APPEND PROPERTY`n  INTERFACE_COMPILE_DEFINITIONS $definitionList)`n"
  Add-Content -Path $TargetsFile -Value $patch
}

function Resolve-LibraryPath {
  param(
    [Parameter(Mandatory)] [string[]]$Patterns,
    [string]$Root = (Join-Path $env:INSTALL_PREFIX "lib")
  )

  foreach ($pattern in $Patterns) {
    $match = Get-ChildItem -Path (Join-Path $Root $pattern) -File -ErrorAction SilentlyContinue |
      Sort-Object FullName |
      Select-Object -First 1
    if ($match) {
      return $match.FullName
    }
  }

  throw "Could not find library matching any of: $($Patterns -join ', ') under $Root"
}

function Resolve-OptionalLibraryPath {
  param(
    [Parameter(Mandatory)] [string[]]$Patterns,
    [string]$Root = (Join-Path $env:INSTALL_PREFIX "lib")
  )

  foreach ($pattern in $Patterns) {
    $match = Get-ChildItem -Path (Join-Path $Root $pattern) -File -ErrorAction SilentlyContinue |
      Sort-Object FullName |
      Select-Object -First 1
    if ($match) {
      return $match.FullName
    }
  }

  return $null
}

function Resolve-ExistingDirectory {
  param([Parameter(Mandatory)] [string[]]$Candidates)

  foreach ($candidate in $Candidates) {
    if (Test-Path -Path $candidate -PathType Container) {
      return (Resolve-Path $candidate).Path
    }
  }

  throw "Could not find any of: $($Candidates -join ', ')"
}

function Copy-DirectoryContents {
  param(
    [Parameter(Mandatory)] [string]$Source,
    [Parameter(Mandatory)] [string]$Destination
  )

  New-Directory $Destination
  Copy-Item -Path (Join-Path $Source "*") -Destination $Destination -Recurse -Force
}

function Install-CudaBundle {
  if ($env:OS -ne "win64") {
    Write-Host "Skipping CUDA bundle for $env:OS"
    return
  }

  Write-Host "Installing CUDA redistributable bundle"
  $cudaRoot = Join-Path $env:INSTALL_PREFIX "cuda"
  $cudaPlatform = "windows-x86_64"
  $archiveExt = "zip"
  $components = @("cuda_cudart", "cuda_crt", "cuda_nvrtc", "libnvptxcompiler")

  if (Test-Path $cudaRoot) {
    Remove-Item -Recurse -Force $cudaRoot
  }
  New-Directory $cudaRoot

  @"
{
  "cuda": {
    "name": "CUDA Toolkit",
    "version": "$($env:CUDA_REDIST_VERSION)"
  }
}
"@ | Set-Content -Path (Join-Path $cudaRoot "version.json")

  foreach ($component in $components) {
    $archiveName = "$component-$cudaPlatform-$($env:CUDA_REDIST_VERSION)-archive.$archiveExt"
    $extractDir = "$component-$cudaPlatform-$($env:CUDA_REDIST_VERSION)-archive"
    $url = "https://developer.download.nvidia.com/compute/cuda/redist/$component/$cudaPlatform/$archiveName"

    Download-File $url $archiveName
    Expand-Archive -Path $archiveName -DestinationPath "." -Force

    $srcInclude = Join-Path $extractDir "include"
    if (Test-Path $srcInclude) {
      Copy-DirectoryContents $srcInclude (Join-Path $cudaRoot "include")
    }

    $srcLib = Join-Path $extractDir "lib"
    if (Test-Path $srcLib) {
      Copy-DirectoryContents $srcLib (Join-Path $cudaRoot "lib")
    }
  }
}

$requiredEnvVars = @(
  "INSTALL_PREFIX",
  "OS",
  "PYTHON_EXE",
  "TARGET_TRIPLE",
  "HOST_TRIPLE",
  "MPIR_MSVC_VERSION",
  "MPFR_MSVC_VERSION"
)

foreach ($name in $requiredEnvVars) {
  if (-not (Get-Item -Path "Env:$name" -ErrorAction SilentlyContinue)) {
    throw "$name is not set"
  }
}

if (-not $env:BOOST_INSTALL_PREFIX) {
  $env:BOOST_INSTALL_PREFIX = $env:INSTALL_PREFIX
}

$buildTag = if ($env:BUILD_TAG) { $env:BUILD_TAG } else { "" }
$installIncludeDir = Join-Path $env:INSTALL_PREFIX "include"
$installLibDir = Join-Path $env:INSTALL_PREFIX "lib"
$pythonExe = (Get-Command $env:PYTHON_EXE -ErrorAction Stop).Source
$qmakeExe = Join-Path $env:INSTALL_PREFIX "bin\qmake.exe"
$env:CMAKE_MSVC_RUNTIME_LIBRARY = if ($env:CMAKE_MSVC_RUNTIME_LIBRARY) {
  $env:CMAKE_MSVC_RUNTIME_LIBRARY
} else {
  'MultiThreaded$<$<CONFIG:Debug>:Debug>'
}
$msvcPlatform = if ($env:OS -eq "win64-arm64") { "ARM64" } else { "x64" }
$msvcPlatformDirCandidates = if ($msvcPlatform -eq "ARM64") { @("ARM64", "arm64") } else { @("x64", "amd64") }

Write-Host "OS = $env:OS"
Write-Host "INSTALL_PREFIX = $env:INSTALL_PREFIX"
Write-Host "BUILD_TAG = $buildTag"
Write-Host "TARGET_TRIPLE = $env:TARGET_TRIPLE"
Write-Host "HOST_TRIPLE = $env:HOST_TRIPLE"
Write-Host "MSVC_PLATFORM = $msvcPlatform"
Write-Host "CMAKE_MSVC_RUNTIME_LIBRARY = $env:CMAKE_MSVC_RUNTIME_LIBRARY"
Write-Host "CMAKE_CXX_FLAGS = $env:CMAKE_CXX_FLAGS"
Write-Host "PYTHON_EXE = $pythonExe"
Write-Host "LLVM_VERSION = $env:LLVM_VERSION"
Write-Host "QT_VERSION = $env:QT_VERSION"
Write-Host "LIBSBML_VERSION = $env:LIBSBML_VERSION"
Write-Host "LIBEXPAT_VERSION = $env:LIBEXPAT_VERSION"
Write-Host "SYMENGINE_VERSION = $env:SYMENGINE_VERSION"
Write-Host "GMP_VERSION = $env:GMP_VERSION"
Write-Host "MPFR_VERSION = $env:MPFR_VERSION"
Write-Host "MPIR_MSVC_VERSION = $env:MPIR_MSVC_VERSION"
Write-Host "MPFR_MSVC_VERSION = $env:MPFR_MSVC_VERSION"
Write-Host "SPDLOG_VERSION = $env:SPDLOG_VERSION"
Write-Host "LIBTIFF_VERSION = $env:LIBTIFF_VERSION"
Write-Host "FMT_VERSION = $env:FMT_VERSION"
Write-Host "TBB_VERSION = $env:TBB_VERSION"
Write-Host "DPL_VERSION = $env:DPL_VERSION"
Write-Host "OPENCV_VERSION = $env:OPENCV_VERSION"
Write-Host "CATCH2_VERSION = $env:CATCH2_VERSION"
Write-Host "BENCHMARK_VERSION = $env:BENCHMARK_VERSION"
Write-Host "CGAL_VERSION = $env:CGAL_VERSION"
Write-Host "BOOST_VERSION = $env:BOOST_VERSION"
Write-Host "BOOST_VERSION_ = $env:BOOST_VERSION_"
Write-Host "BOOST_INSTALL_PREFIX = $env:BOOST_INSTALL_PREFIX"
Write-Host "BOOST_B2_OPTIONS = $env:BOOST_B2_OPTIONS"
Write-Host "QCUSTOMPLOT_VERSION = $env:QCUSTOMPLOT_VERSION"
Write-Host "CEREAL_VERSION = $env:CEREAL_VERSION"
Write-Host "PAGMO_VERSION = $env:PAGMO_VERSION"
Write-Host "BZIP2_VERSION = $env:BZIP2_VERSION"
Write-Host "ZIPPER_VERSION = $env:ZIPPER_VERSION"
Write-Host "COMBINE_VERSION = $env:COMBINE_VERSION"
Write-Host "FUNCTION2_VERSION = $env:FUNCTION2_VERSION"
Write-Host "VTK_VERSION = $env:VTK_VERSION"
Write-Host "SCOTCH_VERSION = $env:SCOTCH_VERSION"
Write-Host "NLOPT_VERSION = $env:NLOPT_VERSION"
Write-Host "CUDA_REDIST_VERSION = $env:CUDA_REDIST_VERSION"
Write-Host "PATH = $env:PATH"
Write-Host "git = $((Get-Command git -ErrorAction Stop).Source)"
git --version
Write-Host "cl = $((Get-Command cl -ErrorAction Stop).Source)"
Write-Host "ninja = $((Get-Command ninja -ErrorAction Stop).Source)"
ninja --version
Write-Host "cmake = $((Get-Command cmake -ErrorAction Stop).Source)"
cmake --version
Write-Host "python = $pythonExe"
& $pythonExe --version
if (Get-Command ccache -ErrorAction SilentlyContinue) {
  ccache --version
}

if (-not (Test-Path $qmakeExe)) {
  throw "qmake.exe not found under $env:INSTALL_PREFIX - setup-ci should have staged sme_deps_qt before build.ps1 runs"
}
& $qmakeExe -v

$zlibLib = Resolve-LibraryPath @("zlibstatic.lib")
Write-Host "Using staged zlib from sme_deps_qt: $zlibLib"

Write-Host "Building nlopt"
Invoke-GitClone "https://github.com/stevengj/nlopt.git" $env:NLOPT_VERSION "nlopt"
Push-Location "nlopt"
New-Directory "build"
Push-Location "build"
$nloptArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DNLOPT_FORTRAN=OFF",
  "-DNLOPT_GUILE=OFF",
  "-DNLOPT_JAVA=OFF",
  "-DNLOPT_MATLAB=OFF",
  "-DNLOPT_OCTAVE=OFF",
  "-DNLOPT_PYTHON=OFF",
  "-DNLOPT_SWIG=OFF"
)
Invoke-CMakeConfigure $nloptArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Installing function2"
Invoke-GitClone "https://github.com/Naios/function2.git" $env:FUNCTION2_VERSION "function2"
Push-Location "function2"
New-Directory "build"
Push-Location "build"
$function2Args = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_TESTING=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX"
)
Invoke-CMakeConfigure $function2Args
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building bzip2"
Download-File "https://sourceware.org/pub/bzip2/$($env:BZIP2_VERSION).tar.gz" "bzip2.tgz"
tar -xf "bzip2.tgz"
Push-Location $env:BZIP2_VERSION
nmake -f makefile.msc "CFLAGS=-DWIN32 -MT -Ox -D_FILE_OFFSET_BITS=64 -nologo"
New-Directory $installLibDir
New-Directory $installIncludeDir
Copy-Item ".\libbz2.lib" $installLibDir -Force
Copy-Item ".\bzlib.h" $installIncludeDir -Force
Pop-Location
$bzip2Lib = Resolve-LibraryPath @("libbz2.lib")

Write-Host "Installing cereal"
Invoke-GitClone "https://github.com/USCiLab/cereal.git" $env:CEREAL_VERSION "cereal"
Push-Location "cereal"
New-Directory "build"
Push-Location "build"
$cerealArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DJUST_INSTALL_CEREAL=ON"
)
Invoke-CMakeConfigure $cerealArgs
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building QCustomPlot"
Download-File "https://www.qcustomplot.com/release/$($env:QCUSTOMPLOT_VERSION)/QCustomPlot-source.tar.gz" "qcustomplot-source.tar.gz"
tar -xf "qcustomplot-source.tar.gz"
Copy-Item -Path ".\qcustomplot-source\*" -Destination ".\qcustomplot" -Recurse -Force
Push-Location "qcustomplot"
New-Directory "build"
Push-Location "build"
$qcustomplotArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DZLIB_INCLUDE_DIR=$installIncludeDir",
  "-DZLIB_LIBRARY_RELEASE=$zlibLib",
  "-DWITH_QT6=ON"
)
Invoke-CMakeConfigure $qcustomplotArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building Boost serialization"
Download-File "https://archives.boost.io/release/$($env:BOOST_VERSION)/source/boost_$($env:BOOST_VERSION_).tar.gz" "boost.tar.gz"
tar -xf "boost.tar.gz"
Push-Location "boost_$($env:BOOST_VERSION_)"
.\bootstrap.bat
$boostB2Args = @(
  "--prefix=$env:BOOST_INSTALL_PREFIX",
  "--with-serialization"
)
if ($env:BOOST_B2_OPTIONS) {
  $boostB2Args += $env:BOOST_B2_OPTIONS -split " "
}
$boostB2Args += @("link=static", "runtime-link=static", "install")
& .\b2 @boostB2Args
Pop-Location

Write-Host "Building benchmark"
Invoke-GitClone "https://github.com/google/benchmark.git" $env:BENCHMARK_VERSION "benchmark"
Push-Location "benchmark"
New-Directory "build"
Push-Location "build"
$benchmarkArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DBENCHMARK_ENABLE_WERROR=OFF",
  "-DBENCHMARK_ENABLE_TESTING=OFF"
)
Invoke-CMakeConfigure $benchmarkArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building Catch2"
Invoke-GitClone "https://github.com/catchorg/Catch2.git" $env:CATCH2_VERSION "Catch2"
Push-Location "Catch2"
New-Directory "build"
Push-Location "build"
$catch2Args = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DCMAKE_CXX_STANDARD=20",
  "-DCMAKE_CXX_STANDARD_REQUIRED=ON",
  "-DCATCH_INSTALL_DOCS=OFF",
  "-DCATCH_CONFIG_NO_POSIX_SIGNALS=1",
  "-DCATCH_INSTALL_EXTRAS=ON"
)
Invoke-CMakeConfigure $catch2Args
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building OpenCV"
Invoke-GitClone "https://github.com/opencv/opencv.git" $env:OPENCV_VERSION "opencv"
Push-Location "opencv"
New-Directory "build"
Push-Location "build"
$opencvArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DBUILD_opencv_apps=OFF",
  "-DBUILD_opencv_calib3d=OFF",
  "-DBUILD_opencv_core=ON",
  "-DBUILD_opencv_dnn=OFF",
  "-DBUILD_opencv_features2d=OFF",
  "-DBUILD_opencv_flann=OFF",
  "-DBUILD_opencv_gapi=OFF",
  "-DBUILD_opencv_highgui=OFF",
  "-DBUILD_opencv_imgcodecs=OFF",
  "-DBUILD_opencv_imgproc=ON",
  "-DBUILD_opencv_java_bindings_generator=OFF",
  "-DBUILD_opencv_js=OFF",
  "-DBUILD_opencv_ml=OFF",
  "-DBUILD_opencv_objdetect=OFF",
  "-DBUILD_opencv_photo=OFF",
  "-DBUILD_opencv_python_bindings_generator=OFF",
  "-DBUILD_opencv_python_tests=OFF",
  "-DBUILD_opencv_stitching=OFF",
  "-DBUILD_opencv_ts=OFF",
  "-DBUILD_opencv_video=OFF",
  "-DBUILD_opencv_videoio=OFF",
  "-DBUILD_opencv_world=OFF",
  "-DBUILD_CUDA_STUBS:BOOL=OFF",
  "-DBUILD_DOCS:BOOL=OFF",
  "-DBUILD_EXAMPLES:BOOL=OFF",
  "-DBUILD_FAT_JAVA_LIB:BOOL=OFF",
  "-DBUILD_IPP_IW:BOOL=OFF",
  "-DBUILD_ITT:BOOL=OFF",
  "-DBUILD_JASPER:BOOL=OFF",
  "-DBUILD_JAVA:BOOL=OFF",
  "-DBUILD_JPEG:BOOL=OFF",
  "-DBUILD_OPENEXR:BOOL=OFF",
  "-DBUILD_PACKAGE:BOOL=OFF",
  "-DBUILD_PERF_TESTS:BOOL=OFF",
  "-DBUILD_PNG:BOOL=OFF",
  "-DBUILD_PROTOBUF:BOOL=OFF",
  "-DBUILD_TBB:BOOL=OFF",
  "-DBUILD_TESTS:BOOL=OFF",
  "-DBUILD_TIFF:BOOL=OFF",
  "-DBUILD_USE_SYMLINKS:BOOL=OFF",
  "-DBUILD_WEBP:BOOL=OFF",
  "-DBUILD_WITH_DEBUG_INFO:BOOL=OFF",
  "-DBUILD_WITH_DYNAMIC_IPP:BOOL=OFF",
  "-DBUILD_ZLIB:BOOL=OFF",
  "-DWITH_1394:BOOL=OFF",
  "-DWITH_ADE:BOOL=OFF",
  "-DWITH_ARAVIS:BOOL=OFF",
  "-DWITH_CLP:BOOL=OFF",
  "-DWITH_CUDA:BOOL=OFF",
  "-DWITH_EIGEN:BOOL=OFF",
  "-DWITH_FFMPEG:BOOL=OFF",
  "-DWITH_FREETYPE:BOOL=OFF",
  "-DWITH_GDAL:BOOL=OFF",
  "-DWITH_GDCM:BOOL=OFF",
  "-DWITH_GPHOTO2:BOOL=OFF",
  "-DWITH_GSTREAMER:BOOL=OFF",
  "-DWITH_GTK:BOOL=OFF",
  "-DWITH_GTK_2_X:BOOL=OFF",
  "-DWITH_HALIDE:BOOL=OFF",
  "-DWITH_HPX:BOOL=OFF",
  "-DWITH_IMGCODEC_HDR:BOOL=OFF",
  "-DWITH_IMGCODEC_PFM:BOOL=OFF",
  "-DWITH_IMGCODEC_PXM:BOOL=OFF",
  "-DWITH_IMGCODEC_SUNRASTER:BOOL=OFF",
  "-DWITH_INF_ENGINE:BOOL=OFF",
  "-DWITH_IPP:BOOL=OFF",
  "-DWITH_ITT:BOOL=OFF",
  "-DWITH_JASPER:BOOL=OFF",
  "-DWITH_JPEG:BOOL=OFF",
  "-DWITH_LAPACK:BOOL=OFF",
  "-DWITH_LIBREALSENSE:BOOL=OFF",
  "-DWITH_MFX:BOOL=OFF",
  "-DWITH_NGRAPH:BOOL=OFF",
  "-DWITH_OPENCL:BOOL=OFF",
  "-DWITH_OPENCLAMDBLAS:BOOL=OFF",
  "-DWITH_OPENCLAMDFFT:BOOL=OFF",
  "-DWITH_OPENCL_SVM:BOOL=OFF",
  "-DWITH_OPENEXR:BOOL=OFF",
  "-DWITH_OPENGL:BOOL=OFF",
  "-DWITH_OPENJPEG:BOOL=OFF",
  "-DWITH_OPENMP:BOOL=OFF",
  "-DWITH_OPENNI:BOOL=OFF",
  "-DWITH_OPENNI2:BOOL=OFF",
  "-DWITH_OPENVX:BOOL=OFF",
  "-DWITH_PLAIDML:BOOL=OFF",
  "-DWITH_PNG:BOOL=OFF",
  "-DWITH_PROTOBUF:BOOL=OFF",
  "-DWITH_PTHREADS_PF:BOOL=OFF",
  "-DWITH_PVAPI:BOOL=OFF",
  "-DWITH_QT:BOOL=OFF",
  "-DWITH_QUIRC:BOOL=OFF",
  "-DWITH_TBB:BOOL=OFF",
  "-DWITH_TIFF:BOOL=OFF",
  "-DWITH_V4L:BOOL=OFF",
  "-DWITH_VA:BOOL=OFF",
  "-DWITH_VA_INTEL:BOOL=OFF",
  "-DWITH_VTK:BOOL=OFF",
  "-DWITH_VULKAN:BOOL=OFF",
  "-DWITH_WEBP:BOOL=OFF",
  "-DWITH_XIMEA:BOOL=OFF",
  "-DWITH_XINE:BOOL=OFF",
  "-DZLIB_INCLUDE_DIR=$installIncludeDir",
  "-DZLIB_LIBRARY_RELEASE=$zlibLib"
)
if ($env:OS -eq "win64-arm64") {
  $opencvArgs += @(
    "-DCPU_BASELINE=NEON",
    "-DCPU_BASELINE_REQUIRE=NEON"
  )
}
Invoke-CMakeConfigure $opencvArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building oneTBB"
Invoke-GitClone "https://github.com/oneapi-src/oneTBB.git" $env:TBB_VERSION "oneTBB"
Push-Location "oneTBB"
git apply --ignore-space-change --ignore-whitespace --verbose "..\tbb.diff"
New-Directory "build"
Push-Location "build"
$tbbArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DTBB_ENABLE_IPO=$env:TBB_ENABLE_IPO",
  "-DTBB_STRICT=OFF",
  "-DTBB_TEST=OFF"
)
Invoke-CMakeConfigure $tbbArgs
# MSVC install expects the full oneTBB static set, including tbbmalloc.
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building oneDPL"
Invoke-GitClone "https://github.com/oneapi-src/oneDPL.git" $env:DPL_VERSION "oneDPL"
Push-Location "oneDPL"
New-Directory "build"
Push-Location "build"
$dplArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DONEDPL_BACKEND=tbb"
)
Invoke-CMakeConfigure $dplArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building pagmo"
Invoke-GitClone "https://github.com/esa/pagmo2.git" $env:PAGMO_VERSION "pagmo2"
Push-Location "pagmo2"
New-Directory "build"
Push-Location "build"
$pagmoArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DBoost_USE_STATIC_LIBS=ON",
  "-DBoost_USE_STATIC_RUNTIME=ON",
  "-DPAGMO_BUILD_STATIC_LIBRARY=ON",
  "-DPAGMO_WITH_NLOPT=ON",
  "-DPAGMO_BUILD_TESTS=OFF"
)
Invoke-CMakeConfigure $pagmoArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building expat"
Invoke-GitClone "https://github.com/libexpat/libexpat.git" $env:LIBEXPAT_VERSION "libexpat"
Push-Location "libexpat"
New-Directory "build"
Push-Location "build"
$expatArgs = @(
  "-GNinja",
  "..\expat",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DEXPAT_BUILD_DOCS=OFF",
  "-DEXPAT_BUILD_EXAMPLES=OFF",
  "-DEXPAT_BUILD_TOOLS=OFF",
  "-DEXPAT_MSVC_STATIC_CRT=ON",
  "-DEXPAT_SHARED_LIBS=OFF",
  "-DEXPAT_BUILD_TESTS:BOOL=OFF"
)
Invoke-CMakeConfigure $expatArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location
$expatLib = Resolve-LibraryPath @("libexpatMT*.lib", "libexpatMD*.lib", "libexpat*.lib")

Write-Host "Building libSBML"
Invoke-GitClone "https://github.com/sbmlteam/libsbml.git" $env:LIBSBML_VERSION "libsbml"
Push-Location "libsbml"
git apply --ignore-space-change --ignore-whitespace --verbose "..\libsbml.diff"
New-Directory "build"
Push-Location "build"
$libsbmlArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DENABLE_SPATIAL=ON",
  "-DWITH_CPP_NAMESPACE=ON",
  "-DWITH_THREADSAFE_PARSER=ON",
  "-DLIBSBML_SKIP_SHARED_LIBRARY=ON",
  "-DWITH_BZIP2=ON",
  "-DLIBBZ_INCLUDE_DIR=$installIncludeDir",
  "-DLIBBZ_LIBRARY=$bzip2Lib",
  "-DWITH_ZLIB=ON",
  "-DZLIB_INCLUDE_DIR=$installIncludeDir",
  "-DZLIB_LIBRARY=$zlibLib",
  "-DLIBZ_INCLUDE_DIR=$installIncludeDir",
  "-DLIBZ_LIBRARY=$zlibLib",
  "-DWITH_SWIG=OFF",
  "-DWITH_LIBXML=OFF",
  "-DWITH_EXPAT=ON",
  "-DEXPAT_INCLUDE_DIR=$installIncludeDir",
  "-DEXPAT_LIBRARY=$expatLib"
)
Invoke-CMakeConfigure $libsbmlArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Add-ImportedTargetCompileDefinitions   -TargetsFile (Join-Path $env:INSTALL_PREFIX "lib\cmake\libsbml-static-targets.cmake")   -TargetName "libsbml-static"   -Definitions @("LIBSBML_STATIC=1", "LIBLAX_STATIC=1")
Pop-Location
Pop-Location

Write-Host "Building libCombine"
Invoke-GitClone "https://github.com/sbmlteam/libCombine.git" $env:COMBINE_VERSION "libCombine"
Push-Location "libCombine"
git submodule update --init --recursive
Push-Location "submodules\zipper"
git checkout $env:ZIPPER_VERSION
Pop-Location
New-Directory "build"
Push-Location "build"
$libCombineArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:BOOST_INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$($env:BOOST_INSTALL_PREFIX);$($env:BOOST_INSTALL_PREFIX)\lib\cmake",
  "-DLIBCOMBINE_SKIP_SHARED_LIBRARY=ON",
  "-DWITH_CPP_NAMESPACE=ON",
  "-DEXTRA_LIBS=$zlibLib;$bzip2Lib;$expatLib",
  "-DZLIB_INCLUDE_DIR=$installIncludeDir",
  "-DZLIB_LIBRARY=$zlibLib"
)
Invoke-CMakeConfigure $libCombineArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Add-ImportedTargetCompileDefinitions   -TargetsFile (Join-Path $env:BOOST_INSTALL_PREFIX "lib\cmake\libCombine-static-targets.cmake")   -TargetName "libCombine-static"   -Definitions @("LIBCOMBINE_STATIC=1")
Pop-Location
Pop-Location

Write-Host "Building fmt"
Invoke-GitClone "https://github.com/fmtlib/fmt.git" $env:FMT_VERSION "fmt"
Push-Location "fmt"
New-Directory "build"
Push-Location "build"
$fmtArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DCMAKE_CXX_STANDARD=20",
  "-DFMT_DOC=OFF",
  "-DFMT_TEST:BOOL=OFF"
)
Invoke-CMakeConfigure $fmtArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building libTIFF"
Invoke-GitClone "https://gitlab.com/libtiff/libtiff.git" $env:LIBTIFF_VERSION "libtiff"
Push-Location "libtiff"
git apply --ignore-space-change --ignore-whitespace --verbose "..\libtiff.diff"
New-Directory "cmake-build"
Push-Location "cmake-build"
$libtiffArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-Djpeg=OFF",
  "-Djpeg12=OFF",
  "-Djbig=OFF",
  "-Dlzma=OFF",
  "-Dlibdeflate=OFF",
  "-Dpixarlog=OFF",
  "-Dold-jpeg=OFF",
  "-Dzstd=OFF",
  "-Dmdi=OFF",
  "-Dwebp=OFF",
  "-Dzlib=OFF",
  "-DGLUT_INCLUDE_DIR=GLUT_INCLUDE_DIR-NOTFOUND",
  "-DOPENGL_INCLUDE_DIR=OPENGL_INCLUDE_DIR-NOTFOUND"
)
Invoke-CMakeConfigure $libtiffArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location
$libtiffLib = Resolve-LibraryPath @("libtiff*.lib", "tiff*.lib")

Write-Host "Building spdlog"
Invoke-GitClone "https://github.com/gabime/spdlog.git" $env:SPDLOG_VERSION "spdlog"
Push-Location "spdlog"
New-Directory "build"
Push-Location "build"
$spdlogArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DCMAKE_CXX_STANDARD=20",
  "-DSPDLOG_BUILD_TESTS=OFF",
  "-DSPDLOG_BUILD_EXAMPLE=OFF",
  "-DSPDLOG_FMT_EXTERNAL=ON",
  "-DSPDLOG_NO_THREAD_ID=ON",
  "-DSPDLOG_NO_ATOMIC_LEVELS=ON"
)
Invoke-CMakeConfigure $spdlogArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building MPIR and MPFR"
# Upstream GMP/MPFR do not ship an MSVC build system, so keep using the
# maintained MPIR/MSVC and MPFR/MSVC forks from the historical branch.
Invoke-GitClonePinnedCommit "https://github.com/BrianGladman/mpir.git" $env:MPIR_MSVC_VERSION "mpir"
$mpirBuildDir = Resolve-ExistingDirectory @("mpir\msvc\vs22", "mpir\msvc\vs19")
Push-Location $mpirBuildDir
msbuild.exe /m /p:Platform=$msvcPlatform /p:Configuration=Release "lib_mpir_gc\lib_mpir_gc.vcxproj"
msbuild.exe /m /p:Platform=$msvcPlatform /p:Configuration=Release "lib_mpir_cxx\lib_mpir_cxx.vcxproj"
New-Directory $installLibDir
New-Directory $installIncludeDir
$mpirReleaseDir = Resolve-ExistingDirectory ($msvcPlatformDirCandidates | ForEach-Object { "..\..\lib\$_\Release" })
Copy-Item -Path (Join-Path $mpirReleaseDir "*.lib") -Destination $installLibDir -Force
Copy-Item -Path (Join-Path $mpirReleaseDir "*.pdb") -Destination $installLibDir -Force -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $mpirReleaseDir "*.h") -Destination $installIncludeDir -Force
Pop-Location
$mpirLib = Resolve-LibraryPath @("mpir.lib", "lib_mpir_gc.lib", "libmpir*.lib")

Invoke-GitClonePinnedCommit "https://github.com/BrianGladman/mpfr.git" $env:MPFR_MSVC_VERSION "mpfr"
$mpfrBuildDir = Resolve-ExistingDirectory @("mpfr\build.vs22", "mpfr\build.vs19")
Push-Location $mpfrBuildDir
$mpfrProject = "lib_mpfr\lib_mpfr.vcxproj"
if ($msvcPlatform -eq "ARM64") {
  $mpfrProjectContents = Get-Content -Path $mpfrProject -Raw
  $mpfrProjectContents = $mpfrProjectContents.Replace("x64", "ARM64").Replace("X64", "ARM64")
  Set-Content -Path $mpfrProject -Value $mpfrProjectContents -Encoding utf8
}
msbuild.exe /m /p:Platform=$msvcPlatform /p:Configuration=Release $mpfrProject
$mpfrReleaseDir = Resolve-ExistingDirectory ($msvcPlatformDirCandidates | ForEach-Object { "lib\$_\Release" })
Copy-Item -Path (Join-Path $mpfrReleaseDir "*.lib") -Destination $installLibDir -Force
Copy-Item -Path (Join-Path $mpfrReleaseDir "*.pdb") -Destination $installLibDir -Force -ErrorAction SilentlyContinue
$mpfrHeaderDir = Resolve-ExistingDirectory ($msvcPlatformDirCandidates | ForEach-Object { "..\lib\$_\Release" })
Copy-Item -Path (Join-Path $mpfrHeaderDir "*.h") -Destination $installIncludeDir -Force
Pop-Location
$mpfrLib = Resolve-LibraryPath @("mpfr*.lib")

Write-Host "Installing CGAL"
Invoke-GitClone "https://github.com/CGAL/cgal.git" $env:CGAL_VERSION "cgal"
Push-Location "cgal"
New-Directory "build"
Push-Location "build"
$cgalArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DWITH_CGAL_ImageIO=OFF",
  "-DWITH_CGAL_Qt5=OFF"
)
Invoke-CMakeConfigure $cgalArgs
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building symengine"
Invoke-GitClone "https://github.com/lkeegan/symengine.git" $env:SYMENGINE_VERSION "symengine"
Push-Location "symengine"
New-Directory "build"
Push-Location "build"
$symengineArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DBUILD_BENCHMARKS=OFF",
  "-DGMP_INCLUDE_DIR=$installIncludeDir",
  "-DGMP_LIBRARY=$mpirLib",
  "-DMPFR_INCLUDE_DIR=$installIncludeDir",
  "-DMPFR_LIBRARY=$mpfrLib",
  "-DWITH_LLVM=ON",
  "-DWITH_COTIRE=OFF",
  "-DWITH_SYSTEM_CEREAL=ON",
  "-DWITH_SYMENGINE_THREAD_SAFE=ON",
  "-DBUILD_TESTS=OFF"
)
Invoke-CMakeConfigure $symengineArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Combining Qt bundled freetype libraries for VTK"
$qtFreetypeLib = Resolve-LibraryPath @("*BundledFreetype*.lib")
$qtLibpngLib = Resolve-LibraryPath @("*BundledLibpng*.lib")
$combinedFreetypeLib = Join-Path $installLibDir "CombinedFreetype.lib"
lib.exe "/OUT:$combinedFreetypeLib" $qtFreetypeLib $qtLibpngLib $zlibLib
$vtkOptions = @(
  "-DFREETYPE_LIBRARY_RELEASE=$combinedFreetypeLib",
  "-DFREETYPE_INCLUDE_DIR_freetype2=$(Join-Path $installIncludeDir 'QtFreetype')",
  "-DFREETYPE_INCLUDE_DIR_ft2build=$(Join-Path $installIncludeDir 'QtFreetype')"
)

Write-Host "Building VTK"
Invoke-GitClone "https://gitlab.kitware.com/lkeegan/VTK.git" $env:VTK_VERSION "VTK"
Push-Location "VTK"
git apply --ignore-space-change --ignore-whitespace --verbose "..\vtk.diff"
New-Directory "build"
Push-Location "build"
$vtkArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DVTK_GROUP_ENABLE_StandAlone=DONT_WANT",
  "-DVTK_GROUP_ENABLE_Rendering=YES",
  "-DVTK_MODULE_ENABLE_VTK_GUISupportQt=YES",
  "-DVTK_MODULE_ENABLE_VTK_RenderingQt=YES",
  "-DVTK_MODULE_USE_EXTERNAL_VTK_expat=ON",
  "-DEXPAT_INCLUDE_DIR=$installIncludeDir",
  "-DEXPAT_LIBRARY=$expatLib",
  "-DVTK_MODULE_USE_EXTERNAL_VTK_fmt=ON",
  "-DVTK_MODULE_USE_EXTERNAL_VTK_tiff=ON",
  "-DTIFF_INCLUDE_DIR=$installIncludeDir",
  "-DTIFF_LIBRARY_RELEASE=$libtiffLib",
  "-DVTK_MODULE_USE_EXTERNAL_VTK_zlib=ON",
  "-DZLIB_INCLUDE_DIR=$installIncludeDir",
  "-DZLIB_LIBRARY_RELEASE=$zlibLib",
  "-DVTK_MODULE_USE_EXTERNAL_VTK_freetype=ON",
  "-DVTK_LEGACY_REMOVE=ON",
  "-DVTK_USE_FUTURE_CONST=ON",
  "-DVTK_USE_FUTURE_BOOL=ON",
  "-DVTK_ENABLE_LOGGING=OFF",
  "-DVTK_USE_CUDA=OFF",
  "-DVTK_USE_MPI=OFF",
  "-DVTK_ENABLE_WRAPPING=OFF"
)
$vtkArgs += $vtkOptions
Invoke-CMakeConfigure $vtkArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Write-Host "Building Scotch"
Invoke-GitClone "https://gitlab.inria.fr/scotch/scotch.git" $env:SCOTCH_VERSION "scotch"
Push-Location "scotch"
git apply --ignore-space-change --ignore-whitespace --verbose "..\scotch.diff"
New-Directory "build"
Push-Location "build"
$scotchArgs = @(
  "-GNinja",
  "..",
  "-DCMAKE_BUILD_TYPE=Release",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX",
  "-DCMAKE_PREFIX_PATH=$env:INSTALL_PREFIX",
  "-DBUILD_PTSCOTCH=OFF",
  "-DBUILD_LIBESMUMPS=OFF",
  "-DBUILD_FORTRAN=OFF",
  "-DUSE_LZMA=OFF",
  "-DUSE_ZLIB=ON",
  "-DZLIB_INCLUDE_DIR=$installIncludeDir",
  "-DZLIB_LIBRARY_RELEASE=$zlibLib",
  "-DUSE_BZ2=ON",
  "-DBZIP2_INCLUDE_DIR=$installIncludeDir",
  "-DBZIP2_LIBRARY_RELEASE=$bzip2Lib"
)
Invoke-CMakeConfigure $scotchArgs
Invoke-CMakeBuild
Invoke-CMakeInstall
Pop-Location
Pop-Location

Install-CudaBundle

if (Get-Command ccache -ErrorAction SilentlyContinue) {
  ccache --show-stats
}

New-Directory "artefacts"
Push-Location "artefacts"
7z a "tmp.tar" $env:INSTALL_PREFIX
7z a "sme_deps_common_$($env:OS)$buildTag.tgz" "tmp.tar"
Remove-Item "tmp.tar"
Pop-Location
