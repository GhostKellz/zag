const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;
const crypto = std.crypto;
const http = std.http;

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

    // Create client
    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    // Download the tarball
    try downloadFile(allocator, &client, url, cache_path);

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
pub fn downloadFile(allocator: Allocator, client: *http.Client, url: []const u8, output_path: []const u8) !void {
    std.debug.print("Downloading {s}...\n", .{url});

    // Make the request
    var headers = http.Headers.init(allocator);
    defer headers.deinit();

    // Set up a buffer for the response
    var req = try client.request(.GET, try std.Uri.parse(url), headers, .{});
    defer req.deinit();

    try req.start();
    try req.wait();

    const status = req.response.status;
    if (status != .ok) {
        return error.HttpRequestFailed;
    }

    // Open the output file
    const cwd = fs.cwd();
    const file = try cwd.createFile(output_path, .{});
    defer file.close();

    // Read the response and write it to the file
    const reader = req.reader();
    var buffer: [8192]u8 = undefined;
    var total_size: usize = 0;

    while (true) {
        const bytes_read = try reader.read(&buffer);
        if (bytes_read == 0) break;

        total_size += bytes_read;
        if (total_size > MAX_DOWNLOAD_SIZE) {
            return error.FileTooLarge;
        }

        try file.writeAll(buffer[0..bytes_read]);
    }

    std.debug.print("Downloaded {d} bytes\n", .{total_size});
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
fn downloadWithCurl(allocator: Allocator, url: []const u8, output_path: []const u8) !void {
    std.debug.print("Downloading with curl: {s}...\n", .{url});

    const argv = [_][]const u8{
        "curl",
        "-L", // Follow redirects
        "-s", // Silent mode
        "-o",
        output_path,
        url,
    };

    const result = try std.process.Child.exec(.{
        .allocator = allocator,
        .argv = &argv,
    });

    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    if (result.term.Exited != 0) {
        std.debug.print("curl error: {s}\n", .{result.stderr});
        return error.CurlFailed;
    }
}
