#!/usr/bin/env bash
# Build an RPM package for Zag
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for required tools
for cmd in rpmbuild; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${RED}Error: $cmd is not installed${NC}"
    echo -e "Please install it with: sudo dnf install rpm-build"
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

# Get the repo root directory
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RPM_DIR="$REPO_ROOT/release/rpm"
BUILD_DIR="$HOME/rpmbuild"

# Create RPM build directories
echo -e "${BLUE}Setting up RPM build environment...${NC}"
mkdir -p $BUILD_DIR/{SOURCES,SPECS,BUILD,RPMS,SRPMS}

# Create a source tarball
echo -e "${BLUE}Creating source tarball...${NC}"
cd "$REPO_ROOT/.."
tar -czf "$BUILD_DIR/SOURCES/zag-$VERSION.tar.gz" --transform="s|zag|zag-$VERSION|" zag

# Copy spec file
cp "$RPM_DIR/zag.spec" "$BUILD_DIR/SPECS/"

# Build the package
echo -e "${BLUE}Building RPM package...${NC}"
rpmbuild -ba "$BUILD_DIR/SPECS/zag.spec"

# Copy RPM to release directory
mkdir -p "$RPM_DIR/packages"
find "$BUILD_DIR/RPMS" -name "zag-*.rpm" -exec cp {} "$RPM_DIR/packages/" \;

echo -e "${GREEN}RPM package created in $RPM_DIR/packages/${NC}"
echo -e "Install with: sudo rpm -i $RPM_DIR/packages/zag-*.rpm"
echo -e "Or: sudo dnf localinstall $RPM_DIR/packages/zag-*.rpm"