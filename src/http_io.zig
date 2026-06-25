const std = @import("std");
const intCast = @import("builtin");
const print = std.debug.print;

pub fn http_listener(io: *const std.Io) void {
    const ip_addr = "0.0.0.0";
    const addr = std.Io.net.IpAddress.parse(ip_addr, 3636) catch |err| {
        print("Failed to parse IP Address: {}\n", .{err});
        return;
    };

    var server = addr.listen(io.*, .{}) catch |err| {
        print("Unable to listen to server: {}\n", .{err});
        return;
    };

    std.debug.print("TCP listening on {s}:{}\n", .{ ip_addr, 3636 });

    while (true) {
        var client = server.accept(io.*) catch |err| {
            print("Unable to accept server requests: {}\n", .{err});
            return;
        };
        defer client.close(io.*); // closes the client once it has served the request(End of scope)

        var reader_buf: [1024]u8 = undefined;

        for (&reader_buf) |*item| {
            item.* = 0;
        }

        var client_reader = client.reader(io.*, reader_buf[0..]);
        const reader = &client_reader.interface;

        while (reader.takeDelimiter('\n') catch |err| {
            print("Unable to take delimiter: {}\n", .{err});
            return;
        }) |line| {
            print("recv {d} bytes: {s}\n", .{ line.len, line });
        }
    }
}
