const std = @import("std");
const http = @import("http.zig");
const storage = @import("storage.zig");
const config = @import("config.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const cfg = try config.load(allocator);
    defer cfg.deinit();

    var tsdb = try storage.TSDB.init(allocator, cfg.data_dir);
    defer tsdb.deinit();

    var server = try http.Server.init(allocator, cfg.listen_addr, &tsdb);
    defer server.deinit();

    std.log.info("Starting Prometheus-like on {s}", .{cfg.listen_addr});
    try server.run();
}