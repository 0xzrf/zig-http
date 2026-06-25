const std = @import("std");
const print = std.debug.print;

export fn http_listener(io: *const std.Io) void {
    // const gpa = init.gpa;

    const addr = std.Io.net.IpAddress.parse("0.0.0.0", 3636) catch |err| {
        print("Failed to parse IP Address: {}\n", .{err});
        return;
    };
    var server = addr.listen(io.*, .{}) catch |err| {
        print("Unable to listen to server: {}\n", .{err});
        return;
    };

    std.debug.print("Starting to listen on port {}", .{3636});

    while (true) {
        var client = server.accept(io.*) catch |err| {
            print("Unable to accept server requests: {}\n", .{err});
            return;
        };
        defer client.close(io.*);
    }
}
