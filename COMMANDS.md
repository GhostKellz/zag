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

Adds a package dependency to your project with full automation.

```bash
zag add username/repo
```

**What it does:**
- Downloads the package tarball from GitHub (currently only GitHub repositories are supported)
- Extracts the package to `.zag/deps/package_name/`
- Validates package structure (checks for build.zig and src/ directory)
- Calculates SHA256 hash of the downloaded tarball
- Adds the dependency to your `build.zig.zon` file
- Updates the `zag.lock` file with exact version information
- **Automatically modifies `build.zig`** to include the new dependency
- Provides fallback instructions if automatic integration fails

**Examples:**
```bash
zag add mitchellh/libxev  # Add libxev from GitHub
zag add ziglang/zig-clap  # Add command-line parser
```

**Directory structure after adding:**
```
your-project/
├── build.zig              # ← Automatically updated!
├── build.zig.zon          # ← Updated with dependency
├── zag.lock               # ← Updated with package info
├── .zag/
│   ├── cache/
│   │   └── mitchellh_libxev.tar.gz
│   └── deps/
│       └── libxev/        # ← Extracted package
│           ├── build.zig
│           ├── src/
│           └── ...
```

**Pro tip:** Add this marker to your `build.zig` for perfect dependency placement:
```zig
// zag:deps - dependencies will be added below this line
```

### `zag remove [package]` / `zag rm [package]`

Removes a package dependency from your project with complete cleanup.

```bash
zag remove package_name
zag rm package_name     # Short alias
```

**What it does:**
- Validates that the package exists in your `build.zig.zon` file
- Removes the dependency from your `build.zig.zon` file
- Updates the `zag.lock` file to remove the package entry
- **Automatically removes the dependency from `build.zig`** (blocks added by `zag add`)
- Deletes the package directory from `.zag/deps/package_name/`
- Provides comprehensive feedback about all actions taken

**Examples:**
```bash
zag remove libxev       # Remove libxev dependency
zag rm zig-clap         # Remove using short alias
```

**Sample output:**
```
Removing package: libxev
Checking build.zig.zon for package libxev...
Removing libxev from build.zig.zon...
Updating lock file...
Removing from build.zig...
  ✓ Removed libxev module definition from build.zig
Removing package directory .zag/deps/libxev...
✅ Successfully removed libxev
Actions taken:
  ✓ Removed from build.zig.zon
  ✓ Updated zag.lock
  ✓ Removed from build.zig (if found)
  ✓ Deleted .zag/deps/libxev/ (if found)
```

**Error handling:**
- If package doesn't exist, shows available packages
- Gracefully handles missing files or directories
- Warns about manual dependencies that couldn't be auto-removed

### `zag update`

Updates all dependencies to their latest versions by re-downloading from GitHub.

```bash
zag update
```

**What it does:**
- Loads the current `build.zig.zon` and `zag.lock` files
- For each dependency, re-downloads the tarball from its GitHub URL
- Computes new SHA256 hash and compares with current hash
- **If hash changed:** Updates both manifest files and extracts new version
- **If unchanged:** Shows "Up to date" status and skips processing
- Provides comprehensive summary of updated vs unchanged packages

**Example output:**
```
Updating dependencies...
Checking 2 dependencies for updates...

📦 Checking libxev...
  🔄 Hash changed! Updating...
    Old: 1220abc123def456
    New: 1220def789abc123
  📁 Extracting to .zag/deps/libxev...

📦 Checking zig-clap...
  ✓ Up to date (hash: 1220fed456abc789)

✅ Updated build.zig.zon
✅ Updated zag.lock

📋 Update Summary:
🔄 Updated packages (1):
  - libxev
✅ Up-to-date packages (1):
  - zig-clap

🚀 Updated 1 package(s). Run 'zig build' to use the latest versions.
```

**Benefits:**
- Keep dependencies current with upstream changes
- Automatically updates both manifest and lock files
- Only re-extracts packages that actually changed
- Maintains reproducible builds with exact hashes
- Clear feedback about what was updated

### `zag clean`

Removes cache and build artifacts to free up disk space.

```bash
zag clean              # Remove .zig-cache and .zag/cache
zag clean --all        # Remove all build artifacts and lock files
```

**What it does:**
- **Default mode:** Removes `.zig-cache/` and `.zag/cache/` directories
- **With `--all` flag:** Also removes `zig-out/` and `zag.lock` files

**Examples:**
```bash
zag clean              # Basic cleanup
zag clean --all        # Complete cleanup including lockfile
```

**Output:**
```
Deleted .zig-cache/
Deleted .zag/cache/
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
zag 0.2.0-dev
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