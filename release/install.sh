#!/usr/bin/env bash
# Zag installer script for Linux systems
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Zig is installed
echo -e "${BLUE}Checking for Zig installation...${NC}"
if ! command -v zig &> /dev/null; then
  echo -e "${RED}Error: Zig is not installed or not in PATH${NC}"
  echo -e "Please install Zig from https://ziglang.org/download/"
  exit 1
fi

ZIG_VERSION=$(zig version)
echo -e "${GREEN}Found Zig: ${ZIG_VERSION}${NC}"

# Check for dependencies
echo -e "${BLUE}Checking for dependencies...${NC}"
for cmd in curl tar git; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${RED}Error: $cmd is not installed${NC}"
    echo -e "Please install $cmd before continuing"
    exit 1
  fi
done
echo -e "${GREEN}All dependencies found${NC}"

# Clone or update repository
INSTALL_DIR="$HOME/.zag"
echo -e "${BLUE}Installing Zag to $INSTALL_DIR${NC}"

if [ -d "$INSTALL_DIR" ]; then
  echo -e "${YELLOW}Found existing installation, updating...${NC}"
  cd "$INSTALL_DIR"
  git pull origin main
else
  echo -e "${BLUE}Cloning repository...${NC}"
  git clone https://github.com/yourusername/zag "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# Build Zag
echo -e "${BLUE}Building Zag...${NC}"
zig build -Doptimize=ReleaseSafe

# Create symlink to path
BINARY_PATH="$INSTALL_DIR/zig-out/bin/zag"
SYMLINK_PATH="$HOME/.local/bin/zag"

mkdir -p "$(dirname "$SYMLINK_PATH")"

if [ -L "$SYMLINK_PATH" ]; then
  echo -e "${YELLOW}Removing old symlink...${NC}"
  rm "$SYMLINK_PATH"
fi

echo -e "${BLUE}Creating symlink to $SYMLINK_PATH${NC}"
ln -s "$BINARY_PATH" "$SYMLINK_PATH"

# Check if directory is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo -e "${YELLOW}Warning: $HOME/.local/bin is not in your PATH${NC}"
  echo -e "Add the following to your ~/.bashrc or ~/.zshrc:"
  echo -e "${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
fi

echo -e "${GREEN}Zag has been installed successfully!${NC}"
echo -e "Run 'zag --version' to verify the installation"
echo -e "Run 'zag help' to see available commands"