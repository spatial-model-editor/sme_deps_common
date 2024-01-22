git clone -b fpicgcc --depth=1 https://github.com/lkeegan/MINGW-packages.git
cd MINGW-packages
cd mingw-w64-gcc
MINGW_ARCH=ucrt64 makepkg-mingw -sLf
pacman -U mingw-w64-gcc-*.pkg.tar.zst
