//! This is the main orchestrator of the http server
//! It'll start listening on port 3636, listen to the incoming packets on the server
//! then send it to the parser to get the appropriate method + route for it,
//! build a response for the request, and finally send back the appropriate respone

const std = @import("std");
const constants = @import("constants.zig");
const Parser = @import("parser.zig").Parser;

const print = std.debug.print;
const IP_ADDR = constants.IP_ADDR;
const PORT = constants.PORT;
const READ_BUF_LIMIT = constants.READ_BUF_LIMIT;

pub fn httpListener(io: *const std.Io) void {
    const addr = std.Io.net.IpAddress.parse(IP_ADDR, PORT) catch |err| {
        print("Failed to parse IP Address: {}\n", .{err});
        return;
    };

    var server = addr.listen(io.*, .{}) catch |err| {
        print("Unable to listen to server: {}\n", .{err});
        return;
    };

    std.debug.print("TCP listening on http://{s}:{}\n", .{ IP_ADDR, PORT });

    while (true) {
        var client = server.accept(io.*) catch |err| {
            print("Unable to accept server requests: {}\n", .{err});
            return;
        };
        defer client.close(io.*); // closes the client once it has served the request(End of scope)

        var reader_buf: [READ_BUF_LIMIT]u8 = undefined;
        var writer_buf: [READ_BUF_LIMIT]u8 = undefined;

        for (&reader_buf, &writer_buf) |*item1, *item2| {
            item1.* = 0;
            item2.* = 0;
        }

        var client_reader = client.reader(io.*, reader_buf[0..]);
        var client_writer = client.writer(io.*, writer_buf[0..]);

        var parser = Parser{ .reader = &client_reader.interface, .writer = &client_writer.interface };
        parser.parseRequest();
    }
}
