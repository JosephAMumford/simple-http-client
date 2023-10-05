const std = @import("std");
const http = std.http;

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var client = http.Client{ .allocator = allocator };

    defer client.deinit();

    //Get user input
    try stdout.writer().print("Enter URL: ", .{});
    var buffer: [100]u8 = undefined;
    const input: []const u8 = (try nextLine(stdin.reader(), &buffer)).?;

    const uri = std.Uri.parse(input) catch unreachable;

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("accept", "*/*");
    try headers.append("connection", "keep-alive");

    var request = try client.request(.GET, uri, headers, .{});
    defer request.deinit();

    try request.start();

    try request.wait();

    // var request = try client.request(.POST, uri, headers, .{});
    // defer request.deinit();
    // request.transfer_encoding = .chunked;
    // try request.start();
    // try request.writer().writeAll("Zig Bits!\n");
    // try request.finish();
    // try request.wait();

    const body = request.reader().readAllAlloc(allocator, 8192) catch unreachable;
    defer allocator.free(body);

    std.log.info("Status: {any}", .{request.response.status});
    std.log.info("Length: {any}", .{request.response.content_length});
    std.log.info("{s}", .{body});
}

pub fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    var line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;

    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}
