#!/bin/sh

set -eu

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
VERSION=demo-broken

mkdir -p ./AppDir
cd ./AppDir

wget --retry-connrefused --tries=30 \
	"https://github.com/jwr1/interstellar/releases/download/v0.7.2/interstellar-linux-x86_64.tar.gz"
tar -xvf ./interstellar-linux-x86_64.tar.gz
rm -f ./interstellar-linux-x86_64.tar.gz

echo '[Desktop Entry]
Type=Application
Name=Interstellar
Exec=interstellar %u
Icon=interstellar
Categories=Network
StartupWMClass=interstellar' > ./interstellar.desktop

wget --retry-connrefused --tries=30 \
	"https://github.com/jwr1/interstellar/blob/main/assets/icons/logo.png?raw=true" -O ./interstellar.png

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -s -k -e -v -p ./interstellar /usr/lib/libGL*
ln -s ../data ./bin/data
ln -s ../../data ./shared/bin/data

# prepare sharun
ln ./sharun ./AppRun
./sharun -g
chmod +x ./AppRun

# make appimage
cd ..
wget --retry-connrefused --tries=30 "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n "$PWD"/AppDir "$PWD"/interstellar-"$VERSION"-anylinux-"$ARCH".AppImage
echo "All done!"


