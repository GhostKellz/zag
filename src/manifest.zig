const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;
const json = std.json;

/// Represents the structure of a build.zig.zon file
pub const ZonFile = struct {
    name: []const u8,
    version: []const u8,
    dependencies: std.StringHashMap(Dependency),
    allocator: Allocator,

    /// A dependency in the build.zig.zon file
    pub const Dependency = struct {
        url: []const u8,
        hash: []const u8,
    };

    /// Creates a new empty ZonFile
    pub fn init(allocator: Allocator) !ZonFile {
        return ZonFile{
            .name = try allocator.dupe(u8, "my-project"),
            .version = try allocator.dupe(u8, "0.1.0"),
            .dependencies = std.StringHashMap(Dependency).init(allocator),
            .allocator = allocator,
        };
    }

    /// Frees all allocated memory
    pub fn deinit(self: *ZonFile) void {
        self.allocator.free(self.name);
        self.allocator.free(self.version);

        var it = self.dependencies.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.url);
            self.allocator.free(entry.value_ptr.hash);
        }

        self.dependencies.deinit();
    }

    /// Loads a ZonFile from the specified file path
    pub fn loadFromFile(allocator: Allocator, file_path: []const u8) !ZonFile {
        const cwd = fs.cwd();

        // Read the file
        const file_content = try cwd.readFileAlloc(allocator, file_path, 1024 * 1024);
        defer allocator.free(file_content);

        return try parseFromString(allocator, file_content);
    }

    /// Parses a ZonFile from a string containing ZON data
    pub fn parseFromString(allocator: Allocator, content: []const u8) !ZonFile {
        // Strip comments from the ZON content before parsing
        const clean_content = try stripComments(allocator, content);
        defer allocator.free(clean_content);

        // Parse the ZON content
        var parser = json.Parser.init(allocator, false);
        defer parser.deinit();

        var tree = try parser.parse(clean_content);
        defer tree.deinit();

        const root = tree.root;

        // Create the ZonFile
        var zon_file = ZonFile{
            .name = try allocator.dupe(u8, root.Object.get("name").?.String),
            .version = try allocator.dupe(u8, root.Object.get("version").?.String),
            .dependencies = std.StringHashMap(Dependency).init(allocator),
            .allocator = allocator,
        };

        // Parse dependencies if they exist
        if (root.Object.get("dependencies")) |deps_node| {
            if (deps_node != .Object) {
                // Empty dependencies section
                return zon_file;
            }

            var deps_it = deps_node.Object.iterator();
            while (deps_it.next()) |entry| {
                const dep_name = entry.key_ptr.*;
                const dep_obj = entry.value_ptr.*;

                if (dep_obj != .Object) continue;

                const url = dep_obj.Object.get("url").?.String;
                const hash = dep_obj.Object.get("hash").?.String;

                try zon_file.addDependency(dep_name, url, hash);
            }
        }

        return zon_file;
    }

    /// Adds a dependency to the ZonFile
    pub fn addDependency(self: *ZonFile, name: []const u8, url: []const u8, hash: []const u8) !void {
        const name_dup = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(name_dup);

        const url_dup = try self.allocator.dupe(u8, url);
        errdefer self.allocator.free(url_dup);

        const hash_dup = try self.allocator.dupe(u8, hash);
        errdefer self.allocator.free(hash_dup);

        try self.dependencies.put(name_dup, Dependency{
            .url = url_dup,
            .hash = hash_dup,
        });
    }

    /// Sets the project name
    pub fn setName(self: *ZonFile, name: []const u8) !void {
        const name_dup = try self.allocator.dupe(u8, name);
        self.allocator.free(self.name);
        self.name = name_dup;
    }

    /// Sets the project version
    pub fn setVersion(self: *ZonFile, version: []const u8) !void {
        const version_dup = try self.allocator.dupe(u8, version);
        self.allocator.free(self.version);
        self.version = version_dup;
    }

    /// Saves the ZonFile to the specified path
    pub fn saveToFile(self: ZonFile, file_path: []const u8) !void {
        const cwd = fs.cwd();

        const file = try cwd.createFile(file_path, .{ .truncate = true });
        defer file.close();

        try self.writeTo(file.writer());
    }

    /// Writes the ZonFile to a writer
    pub fn writeTo(self: ZonFile, writer: anytype) !void {
        try writer.writeAll(".{\n");
        try writer.print("    .name = \"{s}\",\n", .{self.name});
        try writer.print("    .version = \"{s}\",\n", .{self.version});

        try writer.writeAll("    .dependencies = .{\n");

        var it = self.dependencies.iterator();
        var first = true;
        while (it.next()) |entry| {
            if (!first) {
                try writer.writeAll(",\n");
            }
            first = false;

            try writer.print("        .{s} = .{{\n", .{entry.key_ptr.*});
            try writer.print("            .url = \"{s}\",\n", .{entry.value_ptr.url});
            try writer.print("            .hash = \"{s}\",\n", .{entry.value_ptr.hash});
            try writer.writeAll("        }");
        }

        if (self.dependencies.count() > 0) {
            try writer.writeAll("\n");
        }

        try writer.writeAll("    },\n");
        try writer.writeAll("}\n");
    }
};

/// Helper function to strip comments from a ZON string
fn stripComments(allocator: Allocator, content: []const u8) ![]const u8 {
    var result = std.ArrayList(u8).init(allocator);
    errdefer result.deinit();

    var i: usize = 0;
    while (i < content.len) {
        // Skip single line comments
        if (i < content.len - 1 and content[i] == '/' and content[i + 1] == '/') {
            i += 2;
            while (i < content.len and content[i] != '\n') {
                i += 1;
            }
            if (i < content.len) {
                try result.append('\n');
                i += 1;
            }
            continue;
        }

        // Add the character to the result
        try result.append(content[i]);
        i += 1;
    }

    return result.toOwnedSlice();
}
