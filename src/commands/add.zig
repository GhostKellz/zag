const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ZonFile = @import("../manifest.zig").ZonFile;
const LockFile = @import("../lockfile.zig").LockFile;
const downloader = @import("../downloader.zig");

/// Add a dependency to the project - COMPLETE IMPLEMENTATION
pub fn add(allocator: Allocator, package_ref: []const u8) !void {
    std.debug.print("Adding package: {s}\n", .{package_ref});

    // Validate package reference format (should be "user/repo")
    const slash_index = std.mem.indexOf(u8, package_ref, "/");
    if (slash_index == null) {
        std.debug.print("Error: Invalid package reference. Use format 'user/repo' (e.g. 'mitchellh/libxev')\n", .{});
        return error.InvalidPackageReference;
    }

    // Check if build.zig.zon exists
    const zon_path = "build.zig.zon";
    const cwd = fs.cwd();
    
    cwd.access(zon_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("Error: build.zig.zon not found. Run 'zag init' first.\n", .{});
            return error.FileNotFound;
        }
        return err;
    };

    // Extract package name from reference (last part after slash)
    const package_name = package_ref[slash_index.? + 1..];
    
    // Step 1: Download and hash the package
    std.debug.print("Downloading {s}...\n", .{package_ref});
    const download_result = try downloader.downloadAndHashPackage(allocator, package_ref);
    defer {
        allocator.free(download_result.url);
        allocator.free(download_result.hash);
        allocator.free(download_result.cache_path);
    }

    // Step 2: Extract the tarball to deps directory
    try ensureDepsDir();
    const deps_path = try std.fmt.allocPrint(allocator, ".zag/deps/{s}", .{package_name});
    defer allocator.free(deps_path);
    
    std.debug.print("Extracting package to {s}...\n", .{deps_path});
    try extractTarball(allocator, download_result.cache_path, deps_path);

    // Step 3: Load and update build.zig.zon
    std.debug.print("Updating build.zig.zon...\n", .{});
    var zon_file = try ZonFile.loadFromFile(allocator, zon_path);
    defer zon_file.deinit();

    // Add the dependency
    try zon_file.addDependency(package_name, download_result.url, download_result.hash);

    // Save the updated ZON file
    try zon_file.saveToFile(zon_path);

    // Step 4: Update lock file
    std.debug.print("Updating lock file...\n", .{});
    var lock_file = try LockFile.loadFromFile(allocator);
    defer lock_file.deinit();

    try lock_file.addPackage(package_name, download_result.url, download_result.hash, null);
    try lock_file.saveToFile();

    // Step 5: Provide build.zig instructions
    try printBuildInstructions(package_name, deps_path);

    std.debug.print("✅ Successfully added {s}\n", .{package_ref});
    std.debug.print("Package extracted to: {s}\n", .{deps_path});
    std.debug.print("Run 'zig build' to verify the integration.\n", .{});
}

/// Ensure the .zag/deps directory exists
fn ensureDepsDir() !void {
    const cwd = fs.cwd();

    // Create .zag directory if it doesn't exist
    cwd.makeDir(".zag") catch |err| {
        if (err != error.PathAlreadyExists) {
            return err;
        }
    };

    // Create .zag/deps directory if it doesn't exist
    cwd.makeDir(".zag/deps") catch |err| {
        if (err != error.PathAlreadyExists) {
            return err;
        }
    };
}

/// Extract a tarball to a destination directory
fn extractTarball(allocator: Allocator, tarball_path: []const u8, dest_path: []const u8) !void {
    const cwd = fs.cwd();

    // Remove existing directory if it exists
    cwd.deleteTree(dest_path) catch |err| {
        if (err != error.FileNotFound) {
            return err;
        }
    };

    // Create destination directory
    try cwd.makePath(dest_path);

    // Use tar to extract (most reliable cross-platform solution)
    const argv = [_][]const u8{
        "tar",
        "-xzf",
        tarball_path,
        "-C",
        dest_path,
        "--strip-components=1", // Remove the top-level directory from the archive
    };

    var child = std.process.Child.init(&argv, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();
    const term = try child.wait();

    // Read stderr for error messages
    const stderr = try child.stderr.?.reader().readAllAlloc(allocator, 1024 * 1024);
    defer allocator.free(stderr);

    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                std.debug.print("tar extraction failed (exit code {d}): {s}\n", .{ code, stderr });
                return error.ExtractionFailed;
            }
        },
        else => {
            std.debug.print("tar extraction terminated abnormally: {s}\n", .{stderr});
            return error.ExtractionFailed;
        },
    }

    std.debug.print("Package extracted successfully\n", .{});
}

/// Print instructions for integrating the dependency into build.zig
fn printBuildInstructions(package_name: []const u8, deps_path: []const u8) !void {
    std.debug.print("\n", .{});
    std.debug.print("To use this dependency in your project, add the following to your build.zig:\n", .{});
    std.debug.print("\n", .{});
    
    std.debug.print("// Add this near the top where modules are defined:\n", .{});
    std.debug.print("const {s}_mod = b.addModule(\"{s}\", .{{\n", .{ package_name, package_name });
    std.debug.print("    .root_source_file = b.path(\"{s}/src/root.zig\"),\n", .{deps_path});
    std.debug.print("    .target = target,\n", .{});
    std.debug.print("    .optimize = optimize,\n", .{});
    std.debug.print("}});\n", .{});
    std.debug.print("\n", .{});
    
    std.debug.print("// Add this to your executable's imports:\n", .{});
    std.debug.print(".imports = &.{{\n", .{});
    std.debug.print("    .{{ .name = \"{s}\", .module = {s}_mod }},\n", .{ package_name, package_name });
    std.debug.print("    // ... your other imports\n", .{});
    std.debug.print("}},\n", .{});
    std.debug.print("\n", .{});
    
    std.debug.print("// Then in your Zig code, you can use:\n", .{});
    std.debug.print("const {s} = @import(\"{s}\");\n", .{ package_name, package_name });
}