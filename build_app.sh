#!/usr/bin/env bash
#
# Build CatchMouse.app as an Apple-Silicon-native bundle.
#
# Compiles an `arm64` and an `x86_64` slice with swiftc and lipos them into a
# universal binary, then assembles and ad-hoc-signs the .app. Requires only the
# Xcode Command Line Tools (swiftc, lipo, codesign) — no full Xcode install. If
# the x86_64 slice can't be built, it ships arm64-only (still Apple Silicon native).
#
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="CatchMouse"
APP_DIR="build/${APP_NAME}.app"
MIN_MACOS="11"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
SRCS=(Sources/"${APP_NAME}"/*.swift)
FRAMEWORKS=(-framework AppKit -framework Carbon -framework CoreGraphics)

mkdir -p build/arch
slices=()
for arch in arm64 x86_64; do
    echo "› Compiling ${arch} slice …"
    if swiftc -O -sdk "$SDK" -target "${arch}-apple-macos${MIN_MACOS}" \
        "${FRAMEWORKS[@]}" "${SRCS[@]}" -o "build/arch/${APP_NAME}-${arch}" 2>/dev/null; then
        slices+=("build/arch/${APP_NAME}-${arch}")
    else
        echo "  ${arch} slice unavailable — skipping"
    fi
done
[ ${#slices[@]} -gt 0 ] || { echo "error: no architectures built"; exit 1; }

echo "› Assembling ${APP_DIR}"
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
lipo -create "${slices[@]}" -o "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp Resources/Info.plist "${APP_DIR}/Contents/Info.plist"
printf 'APPL????' > "${APP_DIR}/Contents/PkgInfo"
[ -f Resources/icon.icns ] && cp Resources/icon.icns "${APP_DIR}/Contents/Resources/icon.icns"

echo "› Ad-hoc code signing"
codesign --force --sign - "${APP_DIR}" >/dev/null

rm -rf build/arch
echo "› Done — architectures: $(lipo -archs "${APP_DIR}/Contents/MacOS/${APP_NAME}")"
echo "   ${APP_DIR}"
