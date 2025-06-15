const std = @import("std");

/// Prints usage information
pub fn help(_: std.mem.Allocator) !void {
    const usage =
        \\Usage: zag [command] [options]
        \\
        \\Commands:
        \\  init        Initialize a new project
        \\  add         Add a dependency to the project
        \\  remove      Remove a dependency from the project
        \\  update      Update all dependencies to latest versions
        \\  list        List all dependencies in the project
        \\  info        Show detailed information about a package
        \\  fetch       Fetch dependencies
        \\  build       Build the project
        \\  lock        Update the lock file without downloading
        \\  clean       Remove cache and build artifacts
        \\  version     Show zag version
        \\  help        Show this help message
        \\
        \\Command aliases:
        \\  rm          Alias for remove
        \\  ls          Alias for list
        \\
        \\List options:
        \\  list        Show dependencies in table format
        \\  list --json Output dependencies as JSON array
        \\
        \\Clean options:
        \\  clean       Remove .zig-cache and .zag/cache
        \\  clean --all Remove all build artifacts and lock files
        \\
        \\Run 'zag [command] --help' for more information on a specific command.
        \\
    ;
    std.debug.print("{s}", .{usage});
}
