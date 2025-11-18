set -euxo pipefail
export NSUnbufferedIO=YES

# Xcode gives you the exact .xcodeproj path of the current build:
STUB_PROJECT="${PROJECT_FILE_PATH}"          # <- robust: no hard-coded path
STUB_SCHEME="ZiggeoMediaSDK"                 # your stub framework scheme (Shared)
STUB_CONFIG="${CONFIGURATION}"               # Debug/Release from Xcode

# Real device-only vendor framework (adjust if needed)
DEVICE_FW="${SRCROOT}/Frameworks/Device/ZiggeoMediaSDK.framework"

# Where to write the xcframework
OUT_DIR="${SRCROOT}/Frameworks"
OUT_XC="${OUT_DIR}/ZiggeoMediaSDK.xcframework"

# Build products go here
BUILD_DIR="${DERIVED_FILE_DIR}/xcbuild"

echo "PROJECT_FILE_PATH=${PROJECT_FILE_PATH}"
echo "SRCROOT=${SRCROOT}"
echo "CONFIGURATION=${CONFIGURATION}"

# --- Prechecks ---
[[ -d "$STUB_PROJECT" ]] || { echo "❌ Stub .xcodeproj not found at $STUB_PROJECT"; exit 1; }
[[ -d "$DEVICE_FW"   ]] || { echo "❌ Device framework not found at $DEVICE_FW"; exit 1; }

rm -rf "$OUT_XC" "$BUILD_DIR"
mkdir -p "$OUT_DIR" "$BUILD_DIR"

# ---- THIN DEVICE FRAMEWORK TO A SINGLE PLATFORM (iphoneos/arm64) ----
TMP_DIR="${PROJECT_TEMP_DIR}/xc_thin_device"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

THIN_DEVICE_FW="${TMP_DIR}/ZiggeoMediaSDK.framework"
rsync -a "${DEVICE_FW}/" "${THIN_DEVICE_FW}/"

BIN="${THIN_DEVICE_FW}/ZiggeoMediaSDK"
# Keep only arm64 in the device binary (strip any x86_64/i386/arm64e etc.)
lipo -thin arm64 "$BIN" -o "$BIN"

# --- Build simulator stub ---
/usr/bin/xcodebuild \
  -project "$STUB_PROJECT" \
  -scheme "$STUB_SCHEME" \
  -configuration "$STUB_CONFIG" \
  -sdk iphonesimulator \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO \
  ARCHS="arm64 x86_64" \
  -derivedDataPath "$BUILD_DIR" \
  clean build

SIM_FW=$(find "$BUILD_DIR/Build/Products/${STUB_CONFIG}-iphonesimulator" -name "ZiggeoMediaSDK.framework" -maxdepth 3 | head -n1)
[[ -n "${SIM_FW:-}" ]] || { echo "❌ Could not find simulator framework product"; exit 1; }
echo "SIM_FW=${SIM_FW}"

# After you set THIN_DEVICE_FW and BIN and lipo -thin arm64 ...
SWIFT_DIR="${THIN_DEVICE_FW}/Modules/ZiggeoMediaSDK.swiftmodule"
if [ -d "$SWIFT_DIR" ]; then
  echo "Removing Swift module payload from device framework to force ObjC-only import"
  rm -rf "$SWIFT_DIR"
fi

# Some vendors also drop loose .swiftinterface files; nuke any stragglers:
find "${THIN_DEVICE_FW}/Modules" -maxdepth 1 -name "*.swiftinterface" -delete || true
find "${THIN_DEVICE_FW}/Modules" -maxdepth 1 -name "*.swiftdoc" -delete || true


# --- Create xcframework (use THIN_DEVICE_FW) ---
/usr/bin/xcodebuild -create-xcframework \
  -framework "$THIN_DEVICE_FW" \
  -framework "$SIM_FW" \
  -output "$OUT_XC"

# --- Sanity: show slices ---
file "$OUT_XC/ios-arm64/ZiggeoMediaSDK.framework/ZiggeoMediaSDK" || true
file "$OUT_XC/ios-arm64_x86_64-simulator/ZiggeoMediaSDK.framework/ZiggeoMediaSDK" || true

echo "✅ XCFramework created at: $OUT_XC"
