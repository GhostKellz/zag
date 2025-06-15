const std = @import("std");
const zag = @import("zag");

pub fn main() !void {
    // Setup arena allocator for the CLI
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Parse command line arguments
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // If no arguments provided, show help
    if (args.len < 2) {
        try printUsage();
        return;
    }

    // Process the command
    const command = args[1];
    const command_args = if (args.len > 2) args[2..] else &[_][]const u8{};

    // Match the command
    if (std.mem.eql(u8, command, "add")) {
        try handleAddCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "fetch")) {
        try handleFetchCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "init")) {
        try handleInitCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "build")) {
        try handleBuildCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "version")) {
        try handleVersionCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "help")) {
        try handleHelpCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "lock")) {
        try handleLockCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "clean")) {
        try handleCleanCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "remove") or std.mem.eql(u8, command, "rm")) {
        try handleRemoveCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "update")) {
        try handleUpdateCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "info")) {
        try handleInfoCommand(allocator, command_args);
    } else if (std.mem.eql(u8, command, "list") or std.mem.eql(u8, command, "ls")) {
        try handleListCommand(allocator, command_args);
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        try printUsage();
    }
}

fn printUsage() !void {
    try zag.commands.help(std.heap.page_allocator);
}

fn handleAddCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) {
        std.debug.print("Error: No package specified\n", .{});
        std.debug.print("Usage: zag add [package_name]\n", .{});
        return;
    }
    const package_name = args[0];
    std.debug.print("Adding package: {s}\n", .{package_name});
    // TODO: Implement actual package addition
    try zag.commands.add(allocator, package_name);
}

fn handleFetchCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args;
    std.debug.print("Fetching dependencies...\n", .{});
    // TODO: Implement dependency fetching
    try zag.commands.fetch(allocator);
}

fn handleInitCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args;
    try zag.commands.init(allocator);
}

fn handleBuildCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args;
    std.debug.print("Building project...\n", .{});
    // TODO: Implement project building
    try zag.commands.build(allocator);
}

fn handleVersionCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args;
    try zag.commands.version(allocator);
}

fn handleHelpCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args;
    try zag.commands.help(allocator);
}

fn handleLockCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args;
    try zag.commands.lock(allocator);
}

fn handleCleanCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try zag.commands.clean(allocator, args);
}

fn handleRemoveCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) {
        std.debug.print("Error: No package specified\n", .{});
        std.debug.print("Usage: zag remove [package_name]\n", .{});
        std.debug.print("   or: zag rm [package_name]\n", .{});
        return;
    }
    const package_name = args[0];
    try zag.commands.remove(allocator, package_name);
}

fn handleUpdateCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = args; // update command doesn't take arguments currently
    try zag.commands.update(allocator);
}

fn handleInfoCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) {
        std.debug.print("Error: No package specified\n", .{});
        std.debug.print("Usage: zag info [package_name]\n", .{});
        return;
    }
    const package_name = args[0];
    try zag.commands.info(allocator, package_name);
}

fn handleListCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    try zag.commands.list(allocator, args);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
