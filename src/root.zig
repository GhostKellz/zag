//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
pub const commands = @import("commands/mod.zig");

/// Current version of zag
pub const ZAG_VERSION = "0.1.0-dev";

// Advanced print function used in the main.zig example
pub fn advancedPrint() !void {
    std.debug.print("Zag package manager is ready!\n", .{});
}

// Re-export the main commands for convenience
pub const init = commands.init;
pub const add = commands.add;
pub const fetch = commands.fetch;
pub const build = commands.build;
pub const version = commands.version;
pub const help = commands.help;
pub const lock = commands.lock;
