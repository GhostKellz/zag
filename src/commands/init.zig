const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const ZonFile = @import("../manifest.zig").ZonFile;

/// Templates for project scaffolding
const Templates = struct {
    /// Template for a basic main.zig file
    const main_zig =
        \\const std = @import("std");
        \\
        \\pub fn main() !void {
        \\    // Initialize stdout
        \\    const stdout_file = std.io.getStdOut().writer();
        \\    var bw = std.io.bufferedWriter(stdout_file);
        \\    const stdout = bw.writer();
        \\
        \\    try stdout.print("Hello, {s}!\n", .{"world"});
        \\
        \\    try bw.flush(); // don't forget to flush!
        \\}
        \\
        \\test "simple test" {
        \\    try std.testing.expectEqual(10, 3 + 7);
        \\}
        \\
    ;

    /// Template for build.zig file
    const build_zig =
        \\const std = @import("std");
        \\
        \\// Although this function looks imperative, note that its job is to
        \\// declaratively construct a build graph that will be executed by an external
        \\// runner.
        \\pub fn build(b: *std.Build) void {
        \\    // Standard target options allows the person running `zig build` to choose
        \\    // what target to build for. Here we do not override the defaults, which
        \\    // means any target is allowed, and the default is native. Other options
        \\    // for restricting supported target set are available.
        \\    const target = b.standardTargetOptions(.{});
        \\
        \\    // Standard optimization options allow the person running `zig build` to select
        \\    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
        \\    // set a preferred release mode, allowing the user to decide how to optimize.
        \\    const optimize = b.standardOptimizeOption(.{});
        \\
        \\    const exe = b.addExecutable(.{
        \\        .name = "my-project",
        \\        // In this case the main source file is merely a path, however, in more
        \\        // complicated build scripts, this could be a generated file.
        \\        .root_source_file = .{ .path = "src/main.zig" },
        \\        .target = target,
        \\        .optimize = optimize,
        \\    });
        \\
        \\    // This declares intent for the executable to be installed into the
        \\    // standard location when the user invokes the "install" step (the default
        \\    // step when running `zig build`).
        \\    b.installArtifact(exe);
        \\
        \\    // This *creates* a RunStep in the build graph, to be executed when another
        \\    // step is evaluated that depends on it. The next line below will establish
        \\    // such a dependency.
        \\    const run_cmd = b.addRunArtifact(exe);
        \\
        \\    // By making the run step depend on the install step, it will be run from the
        \\    // installation directory rather than directly from within the cache directory.
        \\    // This is not necessary, however, if the application depends on other installed
        \\    // files, this ensures they will be present and in the expected location.
        \\    run_cmd.step.dependOn(b.getInstallStep());
        \\
        \\    // This allows the user to pass arguments to the application in the build
        \\    // command itself, like this: `zig build run -- arg1 arg2 etc`
        \\    if (b.args) |args| {
        \\        run_cmd.addArgs(args);
        \\    }
        \\
        \\    // This creates a build step. It will be visible in the `zig build --help` menu,
        \\    // and can be selected like this: `zig build run`
        \\    // This will evaluate the `run` step rather than the default, which is "install".
        \\    const run_step = b.step("run", "Run the app");
        \\    run_step.dependOn(&run_cmd.step);
        \\
        \\    // Creates a step for unit testing. This only builds the test executable
        \\    // but does not run it.
        \\    const unit_tests = b.addTest(.{
        \\        .root_source_file = .{ .path = "src/main.zig" },
        \\        .target = target,
        \\        .optimize = optimize,
        \\    });
        \\
        \\    const run_unit_tests = b.addRunArtifact(unit_tests);
        \\
        \\    // Similar to creating the run step earlier, this exposes a `test` step to
        \\    // the `zig build --help` menu, providing a way for the user to request
        \\    // running the unit tests.
        \\    const test_step = b.step("test", "Run unit tests");
        \\    test_step.dependOn(&run_unit_tests.step);
        \\}
        \\
    ;
};

/// Initializes a new project by creating template files
pub fn init(allocator: mem.Allocator) !void {
    const cwd = fs.cwd();

    std.debug.print("Initializing new project...\n", .{});

    // Create src directory if it doesn't exist
    cwd.makeDir("src") catch |err| {
        if (err != error.PathAlreadyExists) {
            std.debug.print("Error creating src directory: {}\n", .{err});
            return err;
        }
        // Directory already exists, continue
    };

    // Create main.zig file
    try createFileIfNotExists(cwd, "src/main.zig", Templates.main_zig);

    // Create build.zig file
    try createFileIfNotExists(cwd, "build.zig", Templates.build_zig);

    // Create build.zig.zon using the ZonFile struct
    try createZonFile(allocator);

    std.debug.print("Project initialized successfully!\n", .{});
    std.debug.print("Run 'zig build' to compile your project.\n", .{});
    std.debug.print("Run 'zig build run' to compile and run your project.\n", .{});
}

/// Creates a file with the given content if it doesn't already exist
fn createFileIfNotExists(dir: fs.Dir, path: []const u8, content: []const u8) !void {
    // Check if file already exists
    dir.access(path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            // Create the file
            const file = try dir.createFile(path, .{});
            defer file.close();

            try file.writeAll(content);
            std.debug.print("Created {s}\n", .{path});
            return;
        }
        return err;
    };

    std.debug.print("{s} already exists, skipping\n", .{path});
}

/// Creates the build.zig.zon file using the ZonFile struct
fn createZonFile(allocator: mem.Allocator) !void {
    // Create a new ZonFile with default values
    var zon_file = try ZonFile.init(allocator);
    defer zon_file.deinit();

    // Customize project name based on current directory
    const cwd = fs.cwd();
    var path_buffer: [fs.MAX_PATH_BYTES]u8 = undefined;
    const cwd_path = try cwd.realpath(".", &path_buffer);

    // Extract the directory name from the path
    var dir_name: []const u8 = cwd_path;
    if (std.mem.lastIndexOf(u8, cwd_path, "/")) |idx| {
        dir_name = cwd_path[idx + 1 ..];
    }

    // Set project name based on directory name
    try zon_file.setName(dir_name);

    // Save to disk
    try zon_file.saveToFile("build.zig.zon");

    std.debug.print("Created build.zig.zon for project '{s}'\n", .{dir_name});
}
