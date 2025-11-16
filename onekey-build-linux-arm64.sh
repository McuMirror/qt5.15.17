#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QT_BUILD_TEMP="${QT_BUILD_TEMP:-"$SCRIPT_DIR/build-temp"}"
OPENSSL_ARCHIVE="$SCRIPT_DIR/openssl/openssl-1.1.1w.tar.gz"
OPENSSL_VERSION="openssl-1.1.1w"
TARGET_TAG="linux-arm64"
INSTALL_DIR="$SCRIPT_DIR/Output/linux-arm64"
OPENSSL_ROOT="$QT_BUILD_TEMP/openssl/$TARGET_TAG"
OPENSSL_WORK="$OPENSSL_ROOT/work"
OPENSSL_INSTALL_PREFIX="$OPENSSL_ROOT/install"
OPENSSL_INCLUDE="$OPENSSL_INSTALL_PREFIX/include"
OPENSSL_LIB_RELEASE="$OPENSSL_INSTALL_PREFIX/lib"
OPENSSL_SYMBOL_HIDE_FLAGS="-Wl,--exclude-libs,libssl.a:libcrypto.a"
COMMON_CFLAGS="-fPIC"
export CFLAGS="$COMMON_CFLAGS"
export CXXFLAGS="$COMMON_CFLAGS"

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
  :
}

build_variant() {
  local variant="$1"
  local output="$2"
  local target="$3"
  local mode="${4:-release}"
  local variant_root="$OPENSSL_WORK/$variant"
  rm -rf "$variant_root"
  mkdir -p "$variant_root"
  tar -xf "$OPENSSL_ARCHIVE" -C "$variant_root"
  local src="$variant_root/$OPENSSL_VERSION"
  stage_headers "$src"
  pushd "$src" >/dev/null
  local configure_args=()
  if [[ "$mode" == "debug" ]]; then
    configure_args+=("-d")
  fi
  configure_args+=("$target")
  perl ./Configure "${configure_args[@]}" no-shared
  make -j"$(cpu_count)" build_libs
  mkdir -p "$output"
  cp libssl.a libcrypto.a "$output/"
  popd >/dev/null
}

rm -rf "$OPENSSL_ROOT"
mkdir -p "$OPENSSL_INSTALL_PREFIX"
build_variant release "$OPENSSL_INSTALL_PREFIX/lib" linux-aarch64 release
pushd "$OPENSSL_WORK/release/$OPENSSL_VERSION" >/dev/null
make install_sw INSTALLTOP="$OPENSSL_INSTALL_PREFIX"
popd >/dev/null

export OPENSSL_INCDIR="$OPENSSL_INCLUDE"
export OPENSSL_LIBDIR="$OPENSSL_LIB_RELEASE"
export OPENSSL_LIBS="${OPENSSL_SYMBOL_HIDE_FLAGS} -L\"$OPENSSL_LIB_RELEASE\" -lssl -lcrypto -ldl -lpthread"
export OPENSSL_LIBS_RELEASE="$OPENSSL_LIBS"
export PATH="$SCRIPT_DIR/qtbase/bin:$PATH"

bash ./configure -prefix "$INSTALL_DIR" -confirm-license -opensource -release -force-debug-info -nomake examples -nomake tests -openssl-linked -platform linux-g++ -I "$OPENSSL_INCDIR" -L "$OPENSSL_LIBDIR"
make -j"$(cpu_count)"
make install
