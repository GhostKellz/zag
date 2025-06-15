# Zag Documentation

This document provides comprehensive information about Zag's architecture, advanced features, and development.

## Table of Contents

- [Architecture](#architecture)
- [File Formats](#file-formats)
- [Dependency Resolution](#dependency-resolution)
- [Build Integration](#build-integration)
- [Configuration](#configuration)
- [Development](#development)
- [Troubleshooting](#troubleshooting)

## Architecture

### Overview

Zag is built with a modular architecture that separates concerns:

```
src/
├── main.zig              # CLI entry point and command dispatch
├── root.zig              # Library root, exports commands module
├── commands/             # Command implementations
│   ├── mod.zig          # Commands module exports
│   ├── init.zig         # Project initialization
│   ├── add.zig          # Add dependencies (core feature)
│   ├── fetch.zig        # Fetch all dependencies
│   ├── build.zig        # Build project
│   ├── clean.zig        # Clean artifacts
│   ├── lock.zig         # Lock file management
│   ├── version.zig      # Version display
│   └── help.zig         # Help text
├── manifest.zig         # build.zig.zon parsing and manipulation
├── lockfile.zig         # zag.lock file handling
└── downloader.zig       # HTTP downloads and caching
```

### Core Components

#### 1. Manifest System (`manifest.zig`)

The `ZonFile` struct handles:
- Parsing `build.zig.zon` files (Zig Object Notation)
- Managing project metadata (name, version)
- Handling dependencies with URLs and hashes
- Saving updated manifests

#### 2. Lock File System (`lockfile.zig`)

The `LockFile` struct provides:
- Deterministic dependency resolution
- Timestamp tracking for cache invalidation
- JSON-based storage format
- Version conflict detection

#### 3. Download System (`downloader.zig`)

Features include:
- GitHub tarball resolution
- SHA256 hash verification
- HTTP downloads via curl (robust against Zig stdlib changes)
- Automatic retry with wget fallback
- Caching to `.zag/cache/`

#### 4. Package Extraction

The add command includes:
- Tarball extraction using system `tar`
- Directory structure validation
- Conflict resolution (overwrites existing packages)
- Package structure validation (checks for build.zig, src/)

## File Formats

### build.zig.zon

Zag uses Zig's native `.zon` format for project manifests:

```zig
.{
    .name = "my-project",
    .version = "0.1.0",
    .dependencies = .{
        .libxev = .{
            .url = "https://github.com/mitchellh/libxev/archive/refs/heads/main.tar.gz",
            .hash = "1220abc123...",
        },
        .zig_clap = .{
            .url = "https://github.com/Hejsil/zig-clap/archive/refs/heads/master.tar.gz", 
            .hash = "1220def456...",
        },
    },
}
```

### zag.lock

The lock file uses JSON for wider tool compatibility:

```json
{
  "packages": [
    {
      "name": "libxev",
      "url": "https://github.com/mitchellh/libxev/archive/refs/heads/main.tar.gz",
      "hash": "1220abc123def456...",
      "timestamp": 1701234567
    }
  ]
}
```

## Dependency Resolution

### Current Strategy

Zag currently uses a simple "latest commit" strategy:
1. Resolves `username/repo` to GitHub tarball URL
2. Downloads from `main` or `master` branch
3. Calculates SHA256 hash for reproducibility
4. Stores exact URL and hash in manifest

### Directory Layout

```
project/
├── .zag/
│   ├── cache/                 # Downloaded tarballs
│   │   ├── username_repo.tar.gz
│   │   └── ...
│   └── deps/                  # Extracted packages
│       ├── libxev/
│       │   ├── build.zig
│       │   ├── src/
│       │   └── ...
│       └── zig_clap/
│           ├── build.zig
│           └── src/
├── build.zig                  # ← Auto-modified by zag
├── build.zig.zon             # ← Updated by zag add
└── zag.lock                  # ← Maintained by zag
```

## Build Integration

### Automatic build.zig Modification

When you run `zag add package`, the build.zig file is automatically updated to include the new dependency.

#### Smart Injection

Zag looks for injection points in this order:

1. **Marker-based**: If your build.zig contains:
   ```zig
   // zag:deps - dependencies will be added below this line
   ```
   Dependencies are injected after this line.

2. **Heuristic-based**: Zag tries to find a good location:
   - After module creation (`const mod = b.addModule(...)`)
   - Before executable creation (`const exe = b.addExecutable(...)`)

3. **Fallback**: If automatic injection fails, manual instructions are provided.

#### Generated Code

For a package named `libxev`, Zag generates:

```zig
// Added by zag add libxev
const libxev_mod = b.addModule("libxev", .{
    .root_source_file = b.path(".zag/deps/libxev/src/root.zig"),
    .target = target,
    .optimize = optimize,
});
```

### Manual Integration

If automatic integration fails, add dependencies to your executable's imports:

```zig
const exe = b.addExecutable(.{
    .name = "my-app",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "libxev", .module = libxev_mod },
            // ... other imports
        },
    }),
});
```

## Configuration

Currently, Zag uses minimal configuration and relies on conventions:

- **Cache directory**: `.zag/cache/` (relative to project root)
- **Dependencies directory**: `.zag/deps/` (relative to project root)
- **Manifest file**: `build.zig.zon` (project root)
- **Lock file**: `zag.lock` (project root)

Future versions may support global configuration files.

## Development

### Building Zag

```bash
# Debug build
zig build

# Release build  
zig build -Doptimize=ReleaseSafe

# Run tests
zig build test
```

### Zig Compatibility

Zag is built for **Zig 0.15.0-dev** and later. Key compatibility considerations:

- **JSON API**: Uses the new `std.json.parseFromSlice()` API
- **Process API**: Uses the current `std.process.Child` API
- **File System**: Uses `fs.max_path_bytes` (not `MAX_PATH_BYTES`)
- **HTTP**: Avoids unstable `std.http` in favor of system curl

### Adding New Commands

1. Create `src/commands/newcommand.zig`
2. Implement the command function:
   ```zig
   pub fn newcommand(allocator: std.mem.Allocator) !void {
       // Implementation
   }
   ```
3. Export in `src/commands/mod.zig`:
   ```zig
   pub const newcommand = @import("newcommand.zig").newcommand;
   ```
4. Add to `src/main.zig` command dispatch

## Troubleshooting

### Common Issues

#### "curl not found"
Zag requires `curl` for HTTP downloads. Install curl:
- **Ubuntu/Debian**: `apt install curl`
- **macOS**: `brew install curl` (usually pre-installed)
- **Windows**: Install from https://curl.se/windows/

#### "tar not found"  
Zag requires `tar` for package extraction:
- **Ubuntu/Debian**: `apt install tar` (usually pre-installed)
- **macOS**: Pre-installed
- **Windows**: Install Git for Windows or use WSL

#### "Could not find good injection point in build.zig"
Add this marker to your build.zig where you want dependencies:
```zig
// zag:deps - dependencies will be added below this line
```

#### Package structure validation warnings
```
⚠️  Warning: No build.zig found in package. This may not be a valid Zig package.
⚠️  Warning: No src/ directory found. Package structure may be non-standard.
```

This indicates the downloaded package might not be a standard Zig package. You can still use it, but integration may require manual work.

### Debug Mode

For verbose output during development, use debug builds:
```bash
zig build -Doptimize=Debug
```

### Cache Issues

If you encounter cache corruption:
```bash
zag clean        # Remove cached downloads
zag clean --all  # Remove everything including lock file
```

## Future Enhancements

Planned features for future versions:

- **Semantic versioning**: Support for version ranges like `^1.2.0`
- **Git dependencies**: Direct git repository support
- **Private registries**: Support for private package registries
- **Workspaces**: Multi-package repository support
- **Feature flags**: Optional dependency compilation
- **Cross-platform builds**: Better Windows support
- **Package publishing**: `zag publish` command
- **Package search**: `zag search` functionality

## Contributing

See the main README.md for contribution guidelines.