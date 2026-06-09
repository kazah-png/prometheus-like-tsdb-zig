const std = @import("std");
const net = std.net;
const http = std.http;
const storage = @import("storage.zig");

pub const Server = struct {
    allocator: std.mem.Allocator,
    server: net.Server,
    tsdb: *storage.TSDB,

    pub fn init(allocator: std.mem.Allocator, addr: []const u8, tsdb: *storage.TSDB) !Server {
        const address = try std.net.Address.parseIp(addr, 9090);
        var server = try address.listen(.{
            .reuse_address = true,
        });
        return .{
            .allocator = allocator,
            .server = server,
            .tsdb = tsdb,
        };
    }

    pub fn deinit(self: *Server) void {
        self.server.deinit();
    }

    pub fn run(self: *Server) !void {
        while (true) {
            var conn = try self.server.accept();
            // Spawn hilo por conexión (simplificado)
            _ = std.Thread.spawn(.{}, handleConnection, .{conn, self.tsdb}) catch continue;
        }
    }
};

fn handleConnection(conn: net.Server.Connection, tsdb: *storage.TSDB) void {
    defer conn.stream.close();
    var reader = conn.stream.reader();
    var buffer: [8192]u8 = undefined;
    const first_line = reader.readUntilDelimiter(&buffer, '\n') catch |err| {
        std.log.err("read error: {}", .{err});
        return;
    };
    // Parsear método y path
    if (std.mem.startsWith(u8, first_line, "GET /metrics")) {
        // Exponer métricas internas del TSDB (opcional)
        _ = conn.stream.write("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n") catch return;
        // Aquí se escribirían métricas del servidor
    } else if (std.mem.startsWith(u8, first_line, "POST /api/v1/write")) {
        // Recibir muestras en formato Prometheus (línea a línea)
        _ = conn.stream.write("HTTP/1.1 204 No Content\r\n\r\n") catch return;
        // Leer body y parsear
        // Implementar parsing de texto plano: "metric_name{label1=val1} value timestamp"
    } else if (std.mem.startsWith(u8, first_line, "GET /api/v1/query")) {
        // Parsear query string (ej. ?query=up{job="node"})
        _ = conn.stream.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n") catch return;
        // Ejecutar query y devolver JSON
    } else {
        _ = conn.stream.write("HTTP/1.1 404 Not Found\r\n\r\n") catch return;
    }
}