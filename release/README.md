# Zag Installation

This directory contains various files and scripts to install Zag on different Linux distributions.

## Quick Installation

For a quick installation on most Linux systems, use the installation script:

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/zag/main/release/install.sh | bash
```

This installs Zag to `~/.local/bin/zag`.

## Installation Methods

### Generic Linux (User installation)

For user installation (doesn't require root):

```bash
./install.sh
```

This installs Zag to `~/.zag` and creates a symlink in `~/.local/bin`.

### System-wide Installation

For a system-wide installation (requires root):

```bash
sudo ./install-system.sh
```

This installs Zag to `/usr/local/bin`.

### Arch Linux Installation

To install on Arch Linux:

```bash
cd arch
makepkg -si
```

This builds and installs the package in one command.

### Debian/Ubuntu Installation

To build a Debian package:

```bash
cd debian
./build-deb.sh
```

Install the generated .deb file:

```bash
sudo dpkg -i debian/packages/zag_*.deb
```

### Fedora/RHEL Installation

To build an RPM package:

```bash
cd rpm
./build-rpm.sh
```

Install the generated .rpm file:

```bash
sudo dnf install rpm/packages/zag-*.rpm
```

## Requirements

- Zig 0.11.0 or newer
- curl
- tar
- git

## Verification

After installation, verify that Zag is working by running:

```bash
zag version
```

## Uninstallation

### User installation

```bash
rm ~/.local/bin/zag
rm -rf ~/.zag
```

### System-wide installation

```bash
sudo rm /usr/local/bin/zag
sudo rm -rf /usr/local/share/doc/zag
```

### Package manager installation

For Arch Linux:
```bash
sudo pacman -R zag
```

For Debian/Ubuntu:
```bash
sudo apt remove zag
```

For Fedora/RHEL:
```bash
sudo dnf remove zag
```