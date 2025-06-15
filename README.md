# Zag - A Modern Package Manager for Zig

[![Made with Zig](https://img.shields.io/badge/Made%20with-Zig-orange.svg)](https://ziglang.org)
[![Zig Nightly](https://img.shields.io/badge/Zig-Nightly-blue.svg)](https://ziglang.org/download)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com/ghostkellz/zag)

Zag is a modern, intuitive package manager for the [Zig programming language](https://ziglang.org). It simplifies dependency management and helps you build Zig projects efficiently.

## Features

- 📦 Manage Zig dependencies with ease
- 🔒 Reproducible builds with lockfiles
- 🚀 Automatic dependency resolution and downloading
- 🔄 GitHub integration for seamless package imports
- 🧩 Project scaffolding and initialization
- 📝 Comprehensive documentation and error messages

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/yourusername/zag.git
cd zag

# Build the project
zig build -Doptimize=ReleaseSafe

# Install
zig build install
```

## Getting Started

### Initialize a new project

```bash
mkdir my-project
cd my-project
zag init
```

This will create:
- `src/main.zig` - An example Zig program
- `build.zig` - A build script for your project
- `build.zig.zon` - A manifest file for your project dependencies

### Add a dependency

```bash
zag add mitchellh/libxev
```

This will:
1. Download the GitHub repository
2. Calculate its hash
3. Add it to your `build.zig.zon` file
4. Create/update the `zag.lock` file with exact versions

### Fetch dependencies

```bash
zag fetch
```

Updates all dependencies according to `build.zig.zon`, downloading any missing packages.

## Documentation

For detailed documentation on commands and usage, see [COMMANDS.md](COMMANDS.md).

For advanced usage, configuration options, and architecture details, see [DOCS.md](DOCS.md).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.