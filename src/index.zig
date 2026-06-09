const std = @import("std");

pub const InvertedIndex = struct {
    // label_name -> label_value -> lista de series IDs
    map: std.StringHashMap(std.StringHashMap(std.ArrayList(u64))),

    pub fn init(allocator: std.mem.Allocator) InvertedIndex {
        _ = allocator;
        return .{ .map = std.StringHashMap(std.StringHashMap(std.ArrayList(u64))).init(allocator) };
    }

    pub fn addSeries(self: *InvertedIndex, series_id: u64, labels: []const struct { []const u8, []const u8 }) !void {
        _ = self;
        _ = series_id;
        _ = labels;
    }
};