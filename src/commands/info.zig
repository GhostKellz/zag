const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ZonFile = @import("../manifest.zig").ZonFile;
const LockFile = @import("../lockfile.zig").LockFile;

/// Show detailed information about a specific package
pub fn info(allocator: Allocator, package_name: []const u8) !void {
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

    // Load ZON file
    var zon_file = try ZonFile.loadFromFile(allocator, zon_path);
    defer zon_file.deinit();

    // Check if package exists in dependencies
    const dependency = zon_file.dependencies.get(package_name);
    if (dependency == null) {
        std.debug.print("❌ Package '{s}' not found in dependencies.\n", .{package_name});
        std.debug.print("\nAvailable packages:\n", .{});

        var it = zon_file.dependencies.iterator();
        var count: usize = 0;
        while (it.next()) |entry| {
            std.debug.print("  - {s}\n", .{entry.key_ptr.*});
            count += 1;
        }

        if (count == 0) {
            std.debug.print("  (no dependencies found)\n", .{});
        }

        return error.PackageNotFound;
    }

    // Load lock file for additional info
    var lock_file = try LockFile.loadFromFile(allocator);
    defer lock_file.deinit();

    const locked_pkg = lock_file.getPackage(package_name);

    // Check if package is installed
    const deps_path = try std.fmt.allocPrint(allocator, ".zag/deps/{s}", .{package_name});
    defer allocator.free(deps_path);

    const is_installed = blk: {
        cwd.access(deps_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                break :blk false;
            }
            return err;
        };
        break :blk true;
    };

    // Display package information
    std.debug.print("📦 Package Information: {s}\n", .{package_name});
    std.debug.print("{s}\n", .{"──────────────────────────────────────────────────"});

    // Basic info from ZON file
    const dep = dependency.?;
    std.debug.print("📍 Name:        {s}\n", .{package_name});
    std.debug.print("🔗 URL:         {s}\n", .{dep.url});
    std.debug.print("🔒 Hash:        {s}\n", .{dep.hash[0..16]});
    std.debug.print("📦 Full Hash:   {s}\n", .{dep.hash});

    // Installation status
    if (is_installed) {
        std.debug.print("✅ Status:      Installed\n", .{});
        std.debug.print("📁 Location:    {s}\n", .{deps_path});

        // Try to get file info
        const build_zig_path = try std.fmt.allocPrint(allocator, "{s}/build.zig", .{deps_path});
        defer allocator.free(build_zig_path);

        cwd.access(build_zig_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                std.debug.print("⚠️  Warning:    No build.zig found in package\n", .{});
            } else {
                return err;
            }
        };

        // Check src directory
        const src_path = try std.fmt.allocPrint(allocator, "{s}/src", .{deps_path});
        defer allocator.free(src_path);

        cwd.access(src_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                std.debug.print("⚠️  Warning:    No src/ directory found\n", .{});
            } else {
                return err;
            }
        };
    } else {
        std.debug.print("❌ Status:      Missing (run 'zag fetch' to install)\n", .{});
    }

    // Lock file information
    if (locked_pkg) |pkg| {
        std.debug.print("\n🔒 Lock File Information:\n", .{});
        std.debug.print("🕐 Timestamp:   {d}\n", .{pkg.timestamp});

        // Convert timestamp to human readable
        const time_secs: i64 = @intCast(pkg.timestamp);
        var time_buffer: [64]u8 = undefined;
        const time_str = try std.fmt.bufPrint(&time_buffer, "{d}", .{time_secs});
        std.debug.print("📅 Added:       {s} (Unix timestamp)\n", .{time_str});

        if (pkg.version) |version| {
            std.debug.print("🏷️  Version:     {s}\n", .{version});
        }

        // Check if hashes match
        if (std.mem.eql(u8, dep.hash, pkg.hash)) {
            std.debug.print("✅ Hash Match:  Manifest and lock file are synchronized\n", .{});
        } else {
            std.debug.print("⚠️  Hash Mismatch: Manifest and lock file differ!\n", .{});
            std.debug.print("   Manifest:    {s}\n", .{dep.hash[0..16]});
            std.debug.print("   Lock:        {s}\n", .{pkg.hash[0..16]});
            std.debug.print("   Suggestion:  Run 'zag update' to synchronize\n", .{});
        }
    } else {
        std.debug.print("\n⚠️  Not found in lock file. Run 'zag fetch' to add.\n", .{});
    }

    // Extract package info from URL
    std.debug.print("\n🌐 Repository Information:\n", .{});
    if (std.mem.indexOf(u8, dep.url, "github.com/")) |github_pos| {
        const after_github = dep.url[github_pos + 11 ..]; // Skip "github.com/"
        if (std.mem.indexOf(u8, after_github, "/archive/")) |archive_pos| {
            const repo_path = after_github[0..archive_pos];
            std.debug.print("🏠 Repository:  https://github.com/{s}\n", .{repo_path});

            if (std.mem.indexOf(u8, repo_path, "/")) |slash_pos| {
                const owner = repo_path[0..slash_pos];
                const repo = repo_path[slash_pos + 1 ..];
                std.debug.print("👤 Owner:       {s}\n", .{owner});
                std.debug.print("📚 Repository:  {s}\n", .{repo});
            }
        }
    }

    std.debug.print("\n💡 Commands:\n", .{});
    if (!is_installed) {
        std.debug.print("   zag fetch           # Install this package\n", .{});
    }
    std.debug.print("   zag update          # Update all packages\n", .{});
    std.debug.print("   zag remove {s}   # Remove this package\n", .{package_name});
}
