const std = @import("std");
const Allocator = std.mem.Allocator;
const http = std.http;
const fs = std.fs;
const crypto = std.crypto;

/// Maximum size of downloaded content (100MB)
const MAX_DOWNLOAD_SIZE = 100 * 1024 * 1024;

/// Result of a package download operation
pub const DownloadResult = struct {
    url: []const u8,
    hash: []const u8,
    cache_path: []const u8,

    pub fn deinit(self: *DownloadResult, allocator: Allocator) void {
        allocator.free(self.url);
        allocator.free(self.hash);
        allocator.free(self.cache_path);
    }
};

/// Resolves a package reference (e.g. "mitchellh/libxev") to a GitHub URL
pub fn resolveGitHubUrl(allocator: Allocator, package_ref: []const u8) ![]const u8 {
    // Check if it's a GitHub reference (username/repo format)
    const slash_index = std.mem.indexOf(u8, package_ref, "/");
    if (slash_index == null) {
        return error.InvalidPackageReference;
    }

    // Create GitHub tarball URL
    return std.fmt.allocPrint(allocator, "https://github.com/{s}/archive/refs/heads/main.tar.gz", .{package_ref});
}

/// Downloads a package tarball from a URL, saves it to cache, and calculates its SHA256 hash
pub fn downloadAndHashPackage(allocator: Allocator, package_ref: []const u8) !DownloadResult {
    // Create cache directory if it doesn't exist
    try ensureCacheDir(allocator);

    // Resolve GitHub URL
    const url = try resolveGitHubUrl(allocator, package_ref);
    errdefer allocator.free(url);

    // Generate a unique cache path for this package
    const cache_path = try std.fmt.allocPrint(allocator, ".zag/cache/{s}.tar.gz", .{package_ref});
    errdefer allocator.free(cache_path);

    // Download the tarball directly with improved curl
    try downloadWithCurlImproved(allocator, url, cache_path);

    // Calculate SHA256 hash of the downloaded file
    const hash = try calculateFileHash(allocator, cache_path);
    errdefer allocator.free(hash);

    return DownloadResult{
        .url = url,
        .hash = hash,
        .cache_path = cache_path,
    };
}

/// Ensures the .zag/cache directory exists
pub fn ensureCacheDir(_: Allocator) !void {
    const cwd = fs.cwd();

    // Create .zag directory if it doesn't exist
    cwd.makeDir(".zag") catch |err| {
        if (err != error.PathAlreadyExists) {
            return err;
        }
    };

    // Create .zag/cache directory if it doesn't exist
    cwd.makeDir(".zag/cache") catch |err| {
        if (err != error.PathAlreadyExists) {
            return err;
        }
    };
}

/// Downloads a file from a URL to a local path
pub fn downloadFile(allocator: Allocator, url: []const u8, output_path: []const u8) !void {
    std.debug.print("Downloading {s}...\n", .{url});

    // Use curl instead of std.http due to API changes
    return downloadWithCurl(allocator, url, output_path);
}

/// Calculates SHA256 hash of a file
pub fn calculateFileHash(allocator: Allocator, file_path: []const u8) ![]const u8 {
    const cwd = fs.cwd();
    const file = try cwd.openFile(file_path, .{});
    defer file.close();

    std.debug.print("Calculating SHA256 hash for {s}...\n", .{file_path});

    // Calculate the hash
    var hash = crypto.hash.sha2.Sha256.init(.{});
    var buffer: [8192]u8 = undefined;

    while (true) {
        const bytes_read = try file.read(&buffer);
        if (bytes_read == 0) break;
        hash.update(buffer[0..bytes_read]);
    }

    // Get the digest
    var digest: [crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    hash.final(&digest);

    // Convert the digest to hexadecimal
    const hex_digest = try allocator.alloc(u8, digest.len * 2);
    _ = try std.fmt.bufPrint(hex_digest, "{s}", .{std.fmt.fmtSliceHexLower(&digest)});

    std.debug.print("Hash: {s}\n", .{hex_digest});
    return hex_digest;
}

/// Option to use curl instead of std.http, using a subprocess
/// This implementation is a fallback in case std.http has issues
pub fn downloadWithCurl(allocator: Allocator, url: []const u8, output_path: []const u8) !void {
    std.debug.print("Downloading with curl: {s}...\n", .{url});

    const argv = [_][]const u8{
        "curl",
        "-L", // Follow redirects
        "-s", // Silent mode
        "-o",
        output_path,
        url,
    };

    // Create the child process
    var child = std.process.Child.init(&argv, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    // Wait for the process to complete
    const term = try child.wait();

    // Read output
    const stderr = try child.stderr.?.reader().readAllAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(stderr);

    // Check exit code - success is 0
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                std.debug.print("curl error (exit code {d}): {s}\n", .{ code, stderr });
                return error.CurlFailed;
            }
        },
        else => {
            std.debug.print("curl error (terminated abnormally): {s}\n", .{stderr});
            return error.CurlFailed;
        },
    }
}

/// Improved curl-based downloader with better error handling and validation
pub fn downloadWithCurlImproved(allocator: Allocator, url: []const u8, output_path: []const u8) !void {
    std.debug.print("Downloading {s}...\n", .{url});

    // Ensure output directory exists
    if (std.fs.path.dirname(output_path)) |dir| {
        try std.fs.cwd().makePath(dir);
    }

    const argv = [_][]const u8{
        "curl",
        "-L", // Follow redirects
        "-s", // Silent mode
        "-S", // Show errors even in silent mode
        "--fail", // Fail silently on HTTP errors
        "--max-time",   "30", // 30 second timeout
        "--user-agent", "zag/0.1.0",
        "-o",           output_path,
        url,
    };

    // Create the child process
    var child = std.process.Child.init(&argv, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    // Wait for the process to complete
    const term = try child.wait();

    // Read stderr for error messages
    const stderr = try child.stderr.?.reader().readAllAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(stderr);

    // Check exit code - success is 0
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                std.debug.print("curl failed (exit code {d}): {s}\n", .{ code, stderr });
                // Clean up partial download
                std.fs.cwd().deleteFile(output_path) catch {};
                return error.DownloadFailed;
            }
        },
        else => {
            std.debug.print("curl terminated abnormally: {s}\n", .{stderr});
            std.fs.cwd().deleteFile(output_path) catch {};
            return error.DownloadFailed;
        },
    }

    // Verify the file was actually created and has content
    const file = std.fs.cwd().openFile(output_path, .{}) catch {
        return error.DownloadFailed;
    };
    defer file.close();

    const file_size = try file.getEndPos();
    if (file_size == 0) {
        std.debug.print("Downloaded file is empty\n", .{});
        return error.DownloadFailed;
    }

    std.debug.print("Successfully downloaded {d} bytes\n", .{file_size});
}

/// Fallback downloader using wget (if curl fails)
pub fn downloadWithWget(allocator: Allocator, url: []const u8, output_path: []const u8) !void {
    std.debug.print("Trying wget for {s}...\n", .{url});

    const argv = [_][]const u8{
        "wget",
        "-q", // Quiet mode
        "--timeout=30", // 30 second timeout
        "--user-agent=zag/0.1.0",
        "-O",
        output_path,
        url,
    };

    var child = std.process.Child.init(&argv, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();
    const term = try child.wait();

    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                return error.WgetFailed;
            }
        },
        else => return error.WgetFailed,
    }
}

/// Smart downloader that tries curl first, then wget as fallback
pub fn downloadSmart(allocator: Allocator, url: []const u8, output_path: []const u8) !void {
    downloadWithCurlImproved(allocator, url, output_path) catch |err| {
        if (err == error.DownloadFailed) {
            std.debug.print("curl failed, trying wget...\n", .{});
            return downloadWithWget(allocator, url, output_path);
        }
        return err;
    };
}
