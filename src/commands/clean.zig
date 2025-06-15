const std = @import("std");

pub fn clean(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    const cwd = std.fs.cwd();
    var deleted_any = false;

    const targets = [_][]const u8{
        ".zig-cache",
        ".zag/cache",
    };

    for (targets) |dir| {
        cwd.access(dir, .{}) catch continue;
        try cwd.deleteTree(dir);
        std.debug.print("Deleted {s}/\n", .{dir});
        deleted_any = true;
    }

    if (args.len > 0 and std.mem.eql(u8, args[0], "--all")) {
        const extras = [_][]const u8{
            "zig-out", "zag.lock",
        };
        for (extras) |target| {
            cwd.access(target, .{}) catch continue;
            cwd.deleteTree(target) catch |err| {
                // Could be a file (like zag.lock)
                if (err == error.NotDir) {
                    try cwd.deleteFile(target);
                } else {
                    return err;
                }
            };
            std.debug.print("Deleted {s}\n", .{target});
            deleted_any = true;
        }
    }

    if (!deleted_any) {
        std.debug.print("Nothing to clean.\n", .{});
    }
}
