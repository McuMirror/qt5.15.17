#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QT_BUILD_TEMP="${QT_BUILD_TEMP:-"$SCRIPT_DIR/build-temp"}"
OPENSSL_ARCHIVE="$SCRIPT_DIR/openssl/openssl-1.1.1w.tar.gz"
OPENSSL_VERSION="openssl-1.1.1w"
TARGET_TAG="linux-arm64-debug"
INSTALL_DIR="$SCRIPT_DIR/Output/linux-arm64-debug"
OPENSSL_ROOT="$QT_BUILD_TEMP/openssl/$TARGET_TAG"
OPENSSL_WORK="$OPENSSL_ROOT/work"
OPENSSL_INCLUDE="$OPENSSL_ROOT/include"
OPENSSL_LIB_DEBUG="$OPENSSL_ROOT/lib/debug"
OPENSSL_SYMBOL_HIDE_FLAGS="-Wl,--exclude-libs,libssl.a:libcrypto.a"
COMMON_CFLAGS="-fPIC -fvisibility=hidden"

mkdir -p "$QT_BUILD_TEMP" "$INSTALL_DIR"

if [[ ! -f "$OPENSSL_ARCHIVE" ]]; then
  echo "Missing OpenSSL archive at $OPENSSL_ARCHIVE" >&2
  exit 1
fi

cpu_count() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
  else
    sysctl -n hw.logicalcpu
  fi
}

stage_headers() {
  local src="$1"
  rm -rf "$OPENSSL_INCLUDE"
  mkdir -p "$OPENSSL_INCLUDE"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src/include/" "$OPENSSL_INCLUDE/"
  else
    cp -R "$src/include/." "$OPENSSL_INCLUDE/"
  fi
}

build_variant() {
  local output="$1"
  local target="$2"
  local variant_root="$OPENSSL_WORK/debug"
  rm -rf "$variant_root"
  mkdir -p "$variant_root"
  tar -xf "$OPENSSL_ARCHIVE" -C "$variant_root"
  local src="$variant_root/$OPENSSL_VERSION"
  stage_headers "$src"
  pushd "$src" >/dev/null
  perl ./Configure -d "$target" no-shared "CFLAGS=$COMMON_CFLAGS" "CXXFLAGS=$COMMON_CFLAGS"
  make -j"$(cpu_count)" build_libs
  mkdir -p "$output"
  cp libssl.a libcrypto.a "$output/"
  popd >/dev/null
}

rm -rf "$OPENSSL_ROOT"
mkdir -p "$OPENSSL_LIB_DEBUG"
build_variant "$OPENSSL_LIB_DEBUG" linux-aarch64

export OPENSSL_INCDIR="$OPENSSL_INCLUDE"
export OPENSSL_LIBDIR="$OPENSSL_LIB_DEBUG"
export OPENSSL_LIBS="${OPENSSL_SYMBOL_HIDE_FLAGS} -L\"$OPENSSL_LIB_DEBUG\" -lssl -lcrypto -ldl -lpthread"
export OPENSSL_LIBS_DEBUG="$OPENSSL_LIBS"
export PATH="$SCRIPT_DIR/qtbase/bin:$PATH"

pushd "$SCRIPT_DIR" >/dev/null
./configure -prefix "$INSTALL_DIR" -confirm-license -opensource -debug -force-debug-info -nomake examples -nomake tests -openssl-linked -platform linux-g++ -I "$OPENSSL_INCLUDE" -L "$OPENSSL_LIB_DEBUG"
make -j"$(cpu_count)"
make install
popd >/dev/null
