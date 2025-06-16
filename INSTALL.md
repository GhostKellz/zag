# Installing Zag

This document provides installation instructions for the Zag package manager on various platforms.

## Quick Installation

For a quick installation on most Linux systems:

```bash
curl -sSL https://raw.githubusercontent.com/ghostkellz/zag/main/release/install.sh | bash
```

This installs Zag locally to `~/.local/bin/zag`.

## Requirements

- Zig 0.11.0 or newer
- curl
- tar
- git

## Installation Methods

### From Source (Generic)

```bash
# Clone the repository
git clone https://github.com/ghostkellz/zag.git
cd zag

# Build the project
zig build -Doptimize=ReleaseSafe

# Install (user installation)
cp zig-out/bin/zag ~/.local/bin/

# Or system-wide installation (requires root)
sudo cp zig-out/bin/zag /usr/local/bin/
```

### Arch Linux

#### Using PKGBUILD

```bash
git clone https://github.com/yourusername/zag.git
cd zag/release/arch
makepkg -si
```

#### Using AUR (once available)

```bash
# Using yay
yay -S zag

# Or using paru
paru -S zag
```

### Debian/Ubuntu

```bash
git clone https://github.com/yourusername/zag.git
cd zag/release/debian
./build-deb.sh
sudo dpkg -i debian/packages/zag_*.deb
```

### Fedora/RHEL/CentOS

```bash
git clone https://github.com/yourusername/zag.git
cd zag/release/rpm
./build-rpm.sh
sudo dnf install rpm/packages/zag-*.rpm
```

### Docker

You can also use Zag via Docker:

```bash
# Pull the image
docker pull ghostkellz/zag:latest

# Run a command
docker run --rm ghostkellz/zag:latest help

# Use in a project directory
docker run --rm -v $(pwd):/workspace -w /workspace ghostkellz/zag:latest init
```

Or build the Docker image yourself:

```bash
git clone https://github.com/ghostkellz/zag.git
cd zag/release/docker
./build-docker.sh
```

## Shell Completions

Zag provides shell completion scripts for bash, zsh, and fish.

### Bash Completion

```bash
# System-wide
sudo cp release/completions/zag.bash /usr/share/bash-completion/completions/zag

# Or user-only
mkdir -p ~/.local/share/bash-completion/completions/
cp release/completions/zag.bash ~/.local/share/bash-completion/completions/zag
```

### Zsh Completion

```bash
# System-wide
sudo cp release/completions/zag.zsh /usr/share/zsh/site-functions/_zag

# Or user-only
mkdir -p ~/.zsh/completions/
cp release/completions/zag.zsh ~/.zsh/completions/_zag
echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
```

### Fish Completion

```bash
# User installation
mkdir -p ~/.config/fish/completions/
cp release/completions/zag.fish ~/.config/fish/completions/
```

## Manual Pages

To install the manual page:

```bash
# System-wide
sudo cp release/man/zag.1 /usr/local/share/man/man1/
sudo mandb

# Or user-only
mkdir -p ~/.local/share/man/man1/
cp release/man/zag.1 ~/.local/share/man/man1/
```

Then you can access the manual with:

```bash
man zag
```

## Verification

After installation, verify that Zag is working correctly:

```bash
zag --version
zag help
```

## Uninstallation

### Generic installation

```bash
# If installed to ~/.local/bin
rm ~/.local/bin/zag

# If installed system-wide
sudo rm /usr/local/bin/zag
```

### Package manager installation

```bash
# Arch Linux
sudo pacman -R zag

# Debian/Ubuntu
sudo apt remove zag

# Fedora/RHEL
sudo dnf remove zag
```

### Complete cleanup

To remove all Zag data (including cached packages):

```bash
rm -rf ~/.zag
```