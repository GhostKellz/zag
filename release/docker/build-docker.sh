#!/usr/bin/env bash
# Build a Docker image for Zag
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo -e "Please install Docker before continuing"
    exit 1
fi

# Get the repo root directory
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Get version from root.zig
if [ -f "$REPO_ROOT/src/root.zig" ]; then
    VERSION=$(grep "ZAG_VERSION" "$REPO_ROOT/src/root.zig" | cut -d'"' -f2)
else
    VERSION="0.1.0"
fi

# Set image name and tag
IMAGE_NAME="zag"
IMAGE_TAG="${VERSION}"

# Build the Docker image
echo -e "${BLUE}Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}...${NC}"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -t "${IMAGE_NAME}:latest" -f "$REPO_ROOT/release/docker/Dockerfile" "$REPO_ROOT"

echo -e "${GREEN}Docker image built successfully!${NC}"
echo -e "Run with: docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} [command]"
echo -e "Examples:"
echo -e "  docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} help"
echo -e "  docker run --rm -v \$(pwd):/workspace -w /workspace ${IMAGE_NAME}:${IMAGE_TAG} init"