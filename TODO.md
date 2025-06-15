// TODO: Implement in src/commands/add.zig
// 1. Download package using existing downloader
// 2. Extract tarball to deps/ directory  
// 3. Add dependency to build.zig.zon
// 4. Update build.zig to include the dependency
// 5. Update lock file with verified hash

pub fn add(allocator: std.mem.Allocator, package_ref: []const u8) !void {
    // Current: Just prints message
    // Needed: Full implementation
}