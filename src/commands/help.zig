const std = @import("std");

/// Prints usage information
pub fn help(_: std.mem.Allocator) !void {
    const usage =
        \\Usage: zag [command] [options]
        \\
        \\Commands:
        \\  init        Initialize a new project
        \\  add         Add a dependency to the project
        \\  fetch       Fetch dependencies
        \\  build       Build the project
        \\  lock        Update the lock file without downloading
        \\  version     Show zag version
        \\  help        Show this help message
        \\
        \\Run 'zag [command] --help' for more information on a specific command.
        \\
    ;
    std.debug.print("{s}", .{usage});
}
