const std = @import("std");
const http = std.http;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var client = http.Client{ .allocator = allocator };

    defer client.deinit();

    const uri = std.Uri.parse("http://127.0.0.1:8000/get") catch unreachable;

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("accept", "*/*");

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

    std.log.info("{s}", .{body});
}
