# Zag Commands Documentation

This document provides detailed information about all available commands in the Zag package manager.

## Command Reference

### `zag init`

Initializes a new Zig project with the necessary file structure.

```bash
zag init
```

**What it does:**
- Creates a `src/` directory if it doesn't exist
- Creates a `src/main.zig` file with a Hello World program
- Creates a `build.zig` file with a standard Zig build script
- Creates a `build.zig.zon` file with project metadata

**Options:** None currently available

### `zag add [package]`

Adds a package dependency to your project.

```bash
zag add username/repo
```

**What it does:**
- Downloads the package from GitHub (currently only GitHub repositories are supported)
- Calculates SHA256 hash of the downloaded tarball
- Adds the dependency to your `build.zig.zon` file
- Updates the `zag.lock` file with exact version information

**Examples:**
```bash
zag add mitchellh/libxev  # Add libxev from GitHub
```

### `zag fetch`

Fetches all dependencies specified in your `build.zig.zon` file.

```bash
zag fetch
```

**What it does:**
- Reads the `build.zig.zon` file to determine dependencies
- Compares with `zag.lock` file (if it exists)
- Downloads any missing packages
- Verifies hashes of downloaded packages
- Updates the lock file if needed

**Options:** None currently available

### `zag lock`

Updates or creates the lock file based on your `build.zig.zon` dependencies.

```bash
zag lock
```

**What it does:**
- Reads the `build.zig.zon` file
- Creates or updates the `zag.lock` file with current dependencies
- Doesn't download any packages if they're not cached

**Options:** None currently available

### `zag build`

Builds your project using the Zig build system.

```bash
zag build
```

**What it does:**
- Verifies that `build.zig.zon` exists
- Invokes the Zig build system

**Options:** None currently available. All arguments after the build command are passed to Zig's build system.

### `zag version`

Displays the current version of Zag.

```bash
zag version
```

**Output example:**
```
zag 0.1.0-dev
```

### `zag help`

Displays help information about available commands.

```bash
zag help
```

## Exit Codes

| Code | Description           |
|------|-----------------------|
| 0    | Success               |
| 1    | General error         |
| 2    | File not found        |
| 3    | Invalid command usage |

## Environment Variables

Zag doesn't currently use any environment variables, but they may be added in future versions.