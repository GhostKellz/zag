const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;
const json = std.json;

/// Represents a package entry in the lock file
pub const LockedPackage = struct {
    name: []const u8,
    url: []const u8,
    hash: []const u8,
    version: ?[]const u8,
    timestamp: i64,
};

/// Represents the lock file structure
pub const LockFile = struct {
    packages: std.ArrayList(LockedPackage),
    allocator: Allocator,

    /// Initialize a new, empty lock file
    pub fn init(allocator: Allocator) LockFile {
        return LockFile{
            .packages = std.ArrayList(LockedPackage).init(allocator),
            .allocator = allocator,
        };
    }

    /// Free all allocated memory
    pub fn deinit(self: *LockFile) void {
        for (self.packages.items) |pkg| {
            self.allocator.free(pkg.name);
            self.allocator.free(pkg.url);
            self.allocator.free(pkg.hash);
            if (pkg.version) |version| {
                self.allocator.free(version);
            }
        }
        self.packages.deinit();
    }

    /// Add a package to the lock file
    pub fn addPackage(
        self: *LockFile,
        name: []const u8,
        url: []const u8,
        hash: []const u8,
        version: ?[]const u8,
    ) !void {
        // Check if package already exists, if so update it
        for (self.packages.items) |*pkg| {
            if (std.mem.eql(u8, pkg.name, name)) {
                self.allocator.free(pkg.url);
                self.allocator.free(pkg.hash);
                if (pkg.version) |v| {
                    self.allocator.free(v);
                }

                pkg.url = try self.allocator.dupe(u8, url);
                pkg.hash = try self.allocator.dupe(u8, hash);
                pkg.version = if (version) |v| try self.allocator.dupe(u8, v) else null;
                pkg.timestamp = std.time.timestamp();
                return;
            }
        }

        // Otherwise add a new package
        const new_pkg = LockedPackage{
            .name = try self.allocator.dupe(u8, name),
            .url = try self.allocator.dupe(u8, url),
            .hash = try self.allocator.dupe(u8, hash),
            .version = if (version) |v| try self.allocator.dupe(u8, v) else null,
            .timestamp = std.time.timestamp(),
        };

        try self.packages.append(new_pkg);
    }

    /// Load lock file from disk
    pub fn loadFromFile(allocator: Allocator) !LockFile {
        const cwd = fs.cwd();
        const lock_path = "zag.lock";

        // Check if file exists
        cwd.access(lock_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                // If file doesn't exist, return an empty lock file
                return LockFile.init(allocator);
            }
            return err;
        };

        // Read file
        const file_content = try cwd.readFileAlloc(allocator, lock_path, 10 * 1024 * 1024);
        defer allocator.free(file_content);

        // Parse JSON using new API
        const parsed = try std.json.parseFromSlice(std.json.Value, allocator, file_content, .{});
        defer parsed.deinit();
        const root = parsed.value;

        var lock_file = LockFile.init(allocator);
        errdefer lock_file.deinit();

        // Update JSON value access patterns for new API
        if (root.object.get("packages")) |packages_value| {
            if (packages_value != .array) {
                return error.InvalidLockFile;
            }

            const packages = packages_value.array.items;
            for (packages) |pkg_value| {
                if (pkg_value != .object) continue;

                const pkg_obj = pkg_value.object;

                const name = pkg_obj.get("name").?.string;
                const url = pkg_obj.get("url").?.string;
                const hash = pkg_obj.get("hash").?.string;

                const version = if (pkg_obj.get("version")) |v| v.string else null;
                const timestamp = pkg_obj.get("timestamp").?.integer;

                try lock_file.packages.append(LockedPackage{
                    .name = try allocator.dupe(u8, name),
                    .url = try allocator.dupe(u8, url),
                    .hash = try allocator.dupe(u8, hash),
                    .version = if (version) |v| try allocator.dupe(u8, v) else null,
                    .timestamp = timestamp,
                });
            }
        }

        return lock_file;
    }

    /// Save lock file to disk
    pub fn saveToFile(self: *const LockFile) !void {
        const cwd = fs.cwd();
        const lock_path = "zag.lock";

        var file = try cwd.createFile(lock_path, .{ .truncate = true });
        defer file.close();

        // Format the current date and time
        const timestamp = std.time.timestamp();
        var time_buffer: [64]u8 = undefined;
        const time_str = try std.fmt.bufPrint(&time_buffer, "{d}", .{timestamp});

        // Write the file header (comments)
        try file.writer().print(
            \\// This file is automatically generated by zag.
            \\// Do not edit this file manually.
            \\// Last updated: {s}
            \\
        , .{time_str});

        // Create a JSON output using the new API
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const arena_allocator = arena.allocator();

        // Build packages array
        var packages_array = std.ArrayList(std.json.Value).init(arena_allocator);

        for (self.packages.items) |pkg| {
            var pkg_map = std.json.ObjectMap.init(arena_allocator);

            try pkg_map.put("name", .{ .string = pkg.name });
            try pkg_map.put("url", .{ .string = pkg.url });
            try pkg_map.put("hash", .{ .string = pkg.hash });
            try pkg_map.put("timestamp", .{ .integer = pkg.timestamp });

            if (pkg.version) |version| {
                try pkg_map.put("version", .{ .string = version });
            }

            try packages_array.append(.{ .object = pkg_map });
        }

        // Create root object
        var root_map = std.json.ObjectMap.init(arena_allocator);
        try root_map.put("packages", .{ .array = packages_array });

        const root_value = std.json.Value{ .object = root_map };

        // Write JSON with formatting
        try std.json.stringify(root_value, .{ .whitespace = .indent_2 }, file.writer());

        // Add final newline
        try file.writer().writeAll("\n");
    }

    /// Get a package by name
    pub fn getPackage(self: *const LockFile, name: []const u8) ?LockedPackage {
        for (self.packages.items) |pkg| {
            if (std.mem.eql(u8, pkg.name, name)) {
                return pkg;
            }
        }
        return null;
    }
};
