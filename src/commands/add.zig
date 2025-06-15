const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const ZonFile = @import("../manifest.zig").ZonFile;
const downloader = @import("../downloader.zig");
const LockFile = @import("../lockfile.zig").LockFile;

/// Adds a package dependency to the build.zig.zon file
pub fn add(allocator: mem.Allocator, package_name: []const u8) !void {
    const zon_path = "build.zig.zon";
    const cwd = fs.cwd();

    // Check if file exists
    const file_exists = blk: {
        cwd.access(zon_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                break :blk false;
            }
            return err;
        };
        break :blk true;
    };

    if (!file_exists) {
        std.debug.print("build.zig.zon not found. Run 'zag init' first.\n", .{});
        return error.FileNotFound;
    }

    // Download the package and calculate its hash
    var download_result = try downloader.downloadAndHashPackage(allocator, package_name);
    defer download_result.deinit(allocator);

    std.debug.print("Package downloaded and cached at {s}\n", .{download_result.cache_path});

    // Load existing ZON file
    var zon_file = try ZonFile.loadFromFile(allocator, zon_path);
    defer zon_file.deinit();

    // Extract package name from the full reference (e.g. "mitchellh/libxev" -> "libxev")
    const slash_index = std.mem.lastIndexOf(u8, package_name, "/");
    const simple_name = if (slash_index) |idx| package_name[idx + 1 ..] else package_name;

    // Add the dependency with resolved URL and hash
    try zon_file.addDependency(simple_name, download_result.url, download_result.hash);

    // Save changes back to disk
    try zon_file.saveToFile(zon_path);

    // Update lock file
    var lock_file = try LockFile.loadFromFile(allocator);
    defer lock_file.deinit();

    try lock_file.addPackage(simple_name, download_result.url, download_result.hash, null);
    try lock_file.saveToFile();

    std.debug.print("Successfully added {s} to dependencies and updated zag.lock\n", .{simple_name});
}
