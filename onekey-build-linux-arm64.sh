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
OPENSSL_INCLUDE="$OPENSSL_ROOT/include"
OPENSSL_LIB_RELEASE="$OPENSSL_ROOT/lib/release"
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
  perl ./Configure "${configure_args[@]}" no-shared "CFLAGS=$COMMON_CFLAGS" "CXXFLAGS=$COMMON_CFLAGS"
  make -j"$(cpu_count)" build_libs
  mkdir -p "$output"
  cp libssl.a libcrypto.a "$output/"
  popd >/dev/null
}

rm -rf "$OPENSSL_ROOT"
mkdir -p "$OPENSSL_LIB_RELEASE"
build_variant release "$OPENSSL_LIB_RELEASE" linux-aarch64 release

export OPENSSL_INCDIR="$OPENSSL_INCLUDE"
export OPENSSL_LIBDIR="$OPENSSL_LIB_RELEASE"
export OPENSSL_LIBS="${OPENSSL_SYMBOL_HIDE_FLAGS} -L\"$OPENSSL_LIB_RELEASE\" -lssl -lcrypto -ldl -lpthread"
export OPENSSL_LIBS_RELEASE="$OPENSSL_LIBS"
export PATH="$SCRIPT_DIR/qtbase/bin:$PATH"

bash ./configure -prefix "$INSTALL_DIR" -confirm-license -opensource -release -force-debug-info -nomake examples -nomake tests -openssl-linked -platform linux-g++ -I "$OPENSSL_INCLUDE" -L "$OPENSSL_LIB_RELEASE"
make -j"$(cpu_count)"
make install
popd >/dev/null
