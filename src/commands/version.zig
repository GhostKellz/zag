const std = @import("std");
const root = @import("../root.zig");

/// Prints the current version of zag
pub fn version(_: std.mem.Allocator) !void {
    std.debug.print("zag {s}\n", .{root.ZAG_VERSION});
}
