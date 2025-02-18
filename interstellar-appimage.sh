#!/bin/sh

set -eu

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
VERSION=demo

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
xvfb-run -a -- ./lib4bin -s -k -e -v ./interstellar /usr/lib/libGL*

# unsharun
rm -fv ./lib
mv -v ./shared/lib ./
mv -v ./shared/bin/interstellar ./
rm -rfv ./shared
patchelf --set-interpreter ./lib/ld-linux-x86-64.so.2 ./interstellar
( cd ./lib && find ./*/* -type f -exec ln -s {} ./ \; )

echo '#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"

# since we patched a relative interpreter we have to change cwd
cd "$CURRENTDIR" || exit 1

# We also have to this because the RPATH DOES NOT WORK HERE!!!
export LD_LIBRARY_PATH="$CURRENTDIR/lib"

# set rest of vars
export GIO_MODULE_DIR="$CURRENTDIR/lib/gio/modules"
export FONTCONFIG_FILE="$CURRENTDIR/etc/fonts/fonts.conf"
export GSETTINGS_SCHEMA_DIR="$CURRENTDIR/share/glib-2.0/schemas"
export __EGL_VENDOR_LIBRARY_DIRS="$CURRENTDIR/share/glvnd/egl_vendor.d:/usr/share/glvnd/egl_vendor.d"
export XKB_CONFIG_ROOT="$CURRENTDIR/share/X11/xkb"
export TERMINFO="$CURRENTDIR/share/terminfo"
export XDG_DATA_DIRS="$CURRENTDIR/share:/usr/local/share:/usr/share"

exec "$CURRENTDIR"/interstellar' > ./AppRun
chmod +x ./AppRun

# make appimage
cd ..
wget --retry-connrefused --tries=30 "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n "$PWD"/AppDir "$PWD"/interstellar-"$VERSION"-anylinux-"$ARCH".AppImage
echo "All done!"


