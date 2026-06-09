const std = @import("std");
const fs = std.fs;

pub const WAL = struct {
    file: fs.File,
    buffer: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !WAL {
        const file = try fs.cwd().createFile(path, .{ .read = true });
        return .{
            .file = file,
            .buffer = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *WAL) void {
        self.buffer.deinit();
        self.file.close();
    }

    pub fn append(self: *WAL, data: []const u8) !void {
        _ = try self.file.write(data);
        try self.file.writeByte('\n');
        try self.file.sync();
    }
};