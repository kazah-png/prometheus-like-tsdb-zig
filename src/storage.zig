const std = @import("std");
const wal = @import("wal.zig");
const index = @import("index.zig");

pub const TSDB = struct {
    allocator: std.mem.Allocator,
    wal: *wal.WAL,
    invertedIndex: *index.InvertedIndex,
    series: std.StringHashMap(*Series), // key = metric_name + labels hash

    pub fn init(allocator: std.mem.Allocator, data_dir: []const u8) !TSDB {
        _ = data_dir;
        // Inicializar WAL, índice, etc.
        return .{
            .allocator = allocator,
            .wal = undefined,
            .invertedIndex = undefined,
            .series = std.StringHashMap(*Series).init(allocator),
        };
    }

    pub fn deinit(self: *TSDB) void {
        _ = self;
    }

    pub fn appendSample(self: *TSDB, metric: []const u8, labels: []const u8, value: f64, timestamp: i64) !void {
        _ = metric;
        _ = labels;
        _ = value;
        _ = timestamp;
        // Escribir en WAL, actualizar serie en memoria, actualizar índice invertido
    }
};

const Series = struct {
    id: u64,
    metric: []const u8,
    labels: std.StringHashMap([]const u8),
    samples: std.ArrayList(Sample),
};

const Sample = struct {
    timestamp: i64,
    value: f64,
};