const std = @import("std");

pub const Config = struct {
    listen_addr: []const u8,
    data_dir: []const u8,
    wal_dir: []const u8,
    retention_days: u32,
    allocator: std.mem.Allocator,

    pub fn load(allocator: std.mem.Allocator) !Config {
        // Valores por defecto o leer de variables de entorno
        const listen_addr = try std.process.getEnvVarOwned(allocator, "LISTEN_ADDR") catch "0.0.0.0:9090";
        const data_dir = try std.process.getEnvVarOwned(allocator, "DATA_DIR") catch "./data";
        const wal_dir = try std.process.getEnvVarOwned(allocator, "WAL_DIR") catch "./wal";
        const retention_days = try std.process.getEnvVarOwned(allocator, "RETENTION_DAYS") catch "30";
        const days = try std.fmt.parseInt(u32, retention_days, 10);
        return .{
            .listen_addr = listen_addr,
            .data_dir = data_dir,
            .wal_dir = wal_dir,
            .retention_days = days,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Config) void {
        self.allocator.free(self.listen_addr);
        self.allocator.free(self.data_dir);
        self.allocator.free(self.wal_dir);
    }
};