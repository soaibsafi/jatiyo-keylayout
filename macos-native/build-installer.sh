#!/bin/bash
#
# Builds a macOS .pkg installer for the Jatiyo keyboard layout.
#
# Output: dist/Jatiyo-Installer.pkg
#
# Usage:
#   ./build-installer.sh
#
# Optional environment variables:
#   VERSION              Version string baked into the package (default: 1.0)
#   IDENTIFIER           Package identifier (default: me.soaib.Jatiyo)
#   SIGN_IDENTITY        Developer ID Installer identity for signing (optional)

set -euo pipefail

VERSION="${VERSION:-1.0}"
IDENTIFIER="${IDENTIFIER:-me.soaib.Jatiyo}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
PAYLOAD_DIR="$BUILD_DIR/payload"
RESOURCES_DIR="$SCRIPT_DIR/resources"
COMPONENT_PKG="$BUILD_DIR/Jatiyo-component.pkg"
DISTRIBUTION_XML="$BUILD_DIR/distribution.xml"
FINAL_PKG="$DIST_DIR/Jatiyo-Installer.pkg"

KEYLAYOUT_FILE="$SCRIPT_DIR/jatiyo.keylayout"
ICON_FILE="$SCRIPT_DIR/jatiyo.icns"

if [[ ! -f "$KEYLAYOUT_FILE" ]]; then
    echo "Error: jatiyo.keylayout not found at $KEYLAYOUT_FILE" >&2
    exit 1
fi
if [[ ! -f "$ICON_FILE" ]]; then
    echo "Error: jatiyo.icns not found at $ICON_FILE" >&2
    exit 1
fi

echo "Cleaning previous build artifacts..."
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$PAYLOAD_DIR/Library/Keyboard Layouts"
mkdir -p "$DIST_DIR"

echo "Staging payload..."
# Use ditto with --norsrc/--noextattr/--noqtn to avoid emitting AppleDouble (._*)
# files into the payload.
ditto --norsrc --noextattr --noqtn "$KEYLAYOUT_FILE" "$PAYLOAD_DIR/Library/Keyboard Layouts/jatiyo.keylayout"
ditto --norsrc --noextattr --noqtn "$ICON_FILE"      "$PAYLOAD_DIR/Library/Keyboard Layouts/jatiyo.icns"

# Strip any lingering extended attributes and remove AppleDouble files
# defensively, in case the source files carried them.
xattr -cr "$PAYLOAD_DIR" 2>/dev/null || true
find "$PAYLOAD_DIR" -name '._*' -delete

# Files in /Library/Keyboard Layouts/ should be world-readable.
chmod 644 "$PAYLOAD_DIR/Library/Keyboard Layouts/jatiyo.keylayout"
chmod 644 "$PAYLOAD_DIR/Library/Keyboard Layouts/jatiyo.icns"

echo "Building component package..."
# COPYFILE_DISABLE prevents libc copy routines from emitting AppleDouble
# metadata; --filter strips any ._* files that still slip through.
COPYFILE_DISABLE=1 pkgbuild \
    --root "$PAYLOAD_DIR" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --install-location "/" \
    --ownership recommended \
    --filter '(^|/)\._' \
    --filter '\.DS_Store$' \
    "$COMPONENT_PKG"

echo "Generating distribution XML..."
cat > "$DISTRIBUTION_XML" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>Jatiyo Bengali Keyboard Layout</title>
    <organization>me.soaib</organization>
    <welcome    file="welcome.html"    mime-type="text/html"/>
    <conclusion file="conclusion.html" mime-type="text/html"/>
    <options customize="never" require-scripts="false" hostArchitectures="x86_64,arm64"/>
    <domains enable_localSystem="true"/>
    <choices-outline>
        <line choice="default">
            <line choice="${IDENTIFIER}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="${IDENTIFIER}" visible="false">
        <pkg-ref id="${IDENTIFIER}"/>
    </choice>
    <pkg-ref id="${IDENTIFIER}" version="${VERSION}" onConclusion="none">Jatiyo-component.pkg</pkg-ref>
</installer-gui-script>
EOF

echo "Building distribution package..."
PRODUCTBUILD_ARGS=(
    --distribution "$DISTRIBUTION_XML"
    --package-path "$BUILD_DIR"
    --resources    "$RESOURCES_DIR"
)

if [[ -n "$SIGN_IDENTITY" ]]; then
    PRODUCTBUILD_ARGS+=(--sign "$SIGN_IDENTITY")
fi

productbuild "${PRODUCTBUILD_ARGS[@]}" "$FINAL_PKG"

echo ""
echo "Installer built successfully:"
echo "  $FINAL_PKG"
echo ""
echo "Double-click the .pkg file to install, or run:"
echo "  sudo installer -pkg \"$FINAL_PKG\" -target /"
