#!/usr/bin/env bash
# Build a Debian package for Zag
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for required tools
for cmd in dpkg-deb fakeroot; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${RED}Error: $cmd is not installed${NC}"
    echo -e "Please install it with: sudo apt install $cmd"
    exit 1
  fi
done

# Check if Zig is installed
if ! command -v zig &> /dev/null; then
  echo -e "${RED}Error: Zig is not installed or not in PATH${NC}"
  echo -e "Please install Zig from https://ziglang.org/download/"
  exit 1
fi

# Set version
VERSION="0.1.0"
PACKAGE_NAME="zag_${VERSION}_amd64"
ARCHITECTURE="amd64"

# Get the repo root directory
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/release/debian/build"
PACKAGE_DIR="$BUILD_DIR/$PACKAGE_NAME"

echo -e "${BLUE}Creating package structure...${NC}"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR/DEBIAN"
mkdir -p "$PACKAGE_DIR/usr/bin"
mkdir -p "$PACKAGE_DIR/usr/share/doc/zag"

# Create control file
cat > "$PACKAGE_DIR/DEBIAN/control" << EOF
Package: zag
Version: $VERSION
Section: development
Priority: optional
Architecture: $ARCHITECTURE
Depends: zig (>= 0.11.0), curl, tar
Maintainer: Zag Team <your-email@example.com>
Description: A modern package manager for Zig
 Zag provides seamless dependency management with automatic 
 build integration for Zig projects. It features GitHub integration,
 version tracking, smart build integration, and reproducible builds.
EOF

# Build the binary
echo -e "${BLUE}Building Zag...${NC}"
cd "$REPO_ROOT"
zig build -Doptimize=ReleaseSafe

# Copy binary
cp "$REPO_ROOT/zig-out/bin/zag" "$PACKAGE_DIR/usr/bin/"

# Copy docs
cp "$REPO_ROOT/README.md" "$PACKAGE_DIR/usr/share/doc/zag/"
cp "$REPO_ROOT/COMMANDS.md" "$PACKAGE_DIR/usr/share/doc/zag/"
cp "$REPO_ROOT/DOCS.md" "$PACKAGE_DIR/usr/share/doc/zag/"

# If license exists, copy it
if [ -f "$REPO_ROOT/LICENSE" ]; then
  cp "$REPO_ROOT/LICENSE" "$PACKAGE_DIR/usr/share/doc/zag/"
fi

# Set permissions
chmod 755 "$PACKAGE_DIR/usr/bin/zag"
find "$PACKAGE_DIR/usr/share/doc" -type f -exec chmod 644 {} \;

# Build the package
echo -e "${BLUE}Building Debian package...${NC}"
fakeroot dpkg-deb --build "$PACKAGE_DIR"

# Move to output directory
RELEASE_DIR="$REPO_ROOT/release/debian/packages"
mkdir -p "$RELEASE_DIR"
mv "$PACKAGE_DIR.deb" "$RELEASE_DIR/"

echo -e "${GREEN}Package created: $RELEASE_DIR/$PACKAGE_NAME.deb${NC}"
echo -e "Install with: sudo dpkg -i $RELEASE_DIR/$PACKAGE_NAME.deb"