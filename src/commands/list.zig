const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const ZonFile = @import("../manifest.zig").ZonFile;
const LockFile = @import("../lockfile.zig").LockFile;

/// List all dependencies in the project
pub fn list(allocator: Allocator, args: []const []const u8) !void {
    // Check for --json flag
    const json_output = for (args) |arg| {
        if (std.mem.eql(u8, arg, "--json")) break true;
    } else false;

    // Check if build.zig.zon exists
    const zon_path = "build.zig.zon";
    const cwd = fs.cwd();

    cwd.access(zon_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            if (json_output) {
                std.debug.print("[]", .{});
            } else {
                std.debug.print("Error: build.zig.zon not found. Run 'zag init' first.\n", .{});
            }
            return;
        }
        return err;
    };

    // Load ZON file
    var zon_file = try ZonFile.loadFromFile(allocator, zon_path);
    defer zon_file.deinit();

    // Load lock file for additional info
    var lock_file = try LockFile.loadFromFile(allocator);
    defer lock_file.deinit();

    if (zon_file.dependencies.count() == 0) {
        if (json_output) {
            std.debug.print("[]", .{});
        } else {
            std.debug.print("No dependencies found in build.zig.zon\n", .{});
            std.debug.print("Use 'zag add <package>' to add dependencies.\n", .{});
        }
        return;
    }

    if (json_output) {
        try printJsonOutput(allocator, &zon_file, &lock_file);
    } else {
        try printTableOutput(allocator, &zon_file, &lock_file);
    }
}

/// Print dependencies in a human-readable table format
fn printTableOutput(allocator: Allocator, zon_file: *ZonFile, lock_file: *LockFile) !void {
    std.debug.print("📦 Dependencies for project '{s}' v{s}:\n", .{ zon_file.name, zon_file.version });
    std.debug.print("{s}\n", .{"──────────────────────────────────────────────────────────────────────"});
    std.debug.print("{s:<20} {s:<10} {s:<30} {s}\n", .{ "Name", "Status", "Repository", "Hash" });
    std.debug.print("{s}\n", .{"──────────────────────────────────────────────────────────────────────"});

    var it = zon_file.dependencies.iterator();
    var total: usize = 0;
    var installed: usize = 0;

    while (it.next()) |entry| {
        const pkg_name = entry.key_ptr.*;
        const dep = entry.value_ptr.*;

        // Check if installed
        const deps_path = try std.fmt.allocPrint(allocator, ".zag/deps/{s}", .{pkg_name});
        defer allocator.free(deps_path);

        const is_installed = blk: {
            fs.cwd().access(deps_path, .{}) catch |err| {
                if (err == error.FileNotFound) {
                    break :blk false;
                }
                return err;
            };
            break :blk true;
        };

        if (is_installed) {
            installed += 1;
        }

        // Extract repository info from URL
        var repo_name: []const u8 = "unknown";
        if (std.mem.indexOf(u8, dep.url, "github.com/")) |github_pos| {
            const after_github = dep.url[github_pos + 11 ..];
            if (std.mem.indexOf(u8, after_github, "/archive/")) |archive_pos| {
                repo_name = after_github[0..archive_pos];
            }
        }

        // Status icon
        const status = if (is_installed) "✅ Installed" else "❌ Missing";

        // Truncate hash for display
        const short_hash = dep.hash[0..@min(12, dep.hash.len)];

        std.debug.print("{s:<20} {s:<10} {s:<30} {s}...\n", .{ pkg_name, status, repo_name, short_hash });
        total += 1;
    }

    std.debug.print("{s}\n", .{"──────────────────────────────────────────────────────────────────────"});
    std.debug.print("Total: {d} dependencies, {d} installed, {d} missing\n", .{ total, installed, total - installed });

    if (installed < total) {
        std.debug.print("\n💡 Run 'zag fetch' to install missing dependencies.\n", .{});
    }

    // Check for hash mismatches
    var mismatches: usize = 0;
    it = zon_file.dependencies.iterator();
    while (it.next()) |entry| {
        const pkg_name = entry.key_ptr.*;
        const dep = entry.value_ptr.*;

        if (lock_file.getPackage(pkg_name)) |locked_pkg| {
            if (!std.mem.eql(u8, dep.hash, locked_pkg.hash)) {
                mismatches += 1;
            }
        }
    }

    if (mismatches > 0) {
        std.debug.print("\n⚠️  Warning: {d} package(s) have hash mismatches between manifest and lock file.\n", .{mismatches});
        std.debug.print("💡 Run 'zag update' to synchronize.\n", .{});
    }
}

/// Print dependencies in JSON format
fn printJsonOutput(allocator: Allocator, zon_file: *ZonFile, lock_file: *LockFile) !void {
    var json_array = std.ArrayList(u8).init(allocator);
    defer json_array.deinit();

    try json_array.appendSlice("[\n");

    var it = zon_file.dependencies.iterator();
    var first = true;

    while (it.next()) |entry| {
        if (!first) {
            try json_array.appendSlice(",\n");
        }
        first = false;

        const pkg_name = entry.key_ptr.*;
        const dep = entry.value_ptr.*;

        // Check if installed
        const deps_path = try std.fmt.allocPrint(allocator, ".zag/deps/{s}", .{pkg_name});
        defer allocator.free(deps_path);

        const is_installed = blk: {
            fs.cwd().access(deps_path, .{}) catch |err| {
                if (err == error.FileNotFound) {
                    break :blk false;
                }
                return err;
            };
            break :blk true;
        };

        // Get lock file info
        const locked_pkg = lock_file.getPackage(pkg_name);
        const timestamp = if (locked_pkg) |pkg| pkg.timestamp else 0;
        const version = if (locked_pkg) |pkg| pkg.version else null;

        // Extract repository info
        var owner: []const u8 = "unknown";
        var repo: []const u8 = "unknown";
        if (std.mem.indexOf(u8, dep.url, "github.com/")) |github_pos| {
            const after_github = dep.url[github_pos + 11 ..];
            if (std.mem.indexOf(u8, after_github, "/archive/")) |archive_pos| {
                const repo_path = after_github[0..archive_pos];
                if (std.mem.indexOf(u8, repo_path, "/")) |slash_pos| {
                    owner = repo_path[0..slash_pos];
                    repo = repo_path[slash_pos + 1 ..];
                }
            }
        }

        // Build JSON object
        try json_array.appendSlice("  {\n");
        try json_array.writer().print("    \"name\": \"{s}\",\n", .{pkg_name});
        try json_array.writer().print("    \"url\": \"{s}\",\n", .{dep.url});
        try json_array.writer().print("    \"hash\": \"{s}\",\n", .{dep.hash});
        try json_array.writer().print("    \"installed\": {},\n", .{is_installed});
        try json_array.writer().print("    \"location\": \"{s}\",\n", .{deps_path});
        try json_array.writer().print("    \"owner\": \"{s}\",\n", .{owner});
        try json_array.writer().print("    \"repository\": \"{s}\",\n", .{repo});
        try json_array.writer().print("    \"timestamp\": {d}", .{timestamp});

        if (version) |v| {
            try json_array.writer().print(",\n    \"version\": \"{s}\"", .{v});
        }

        try json_array.appendSlice("\n  }");
    }

    try json_array.appendSlice("\n]\n");

    // Print the JSON
    std.debug.print("{s}", .{json_array.items});
}
