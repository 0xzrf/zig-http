//! This is the main orchestrator of the http server
//! It'll start listening on port 3636, listen to the incoming packets on the server
//! then send it to the parser to get the appropriate method + route for it,
//! build a response for the request, and finally send back the appropriate respone

const std = @import("std");
const constants = @import("constants.zig");
const routes = @import("routes/mod.zig");
const types = @import("types.zig");
const DB = @import("db.zig").DB;

const Routes = types.Routes;
const Parser = @import("parser.zig").Parser;

const print = std.debug.print;
const IP_ADDR = constants.IP_ADDR;
const PORT = constants.PORT;
const BUF_LIMIT = constants.BUF_LIMIT;
const BAD_REQUEST_RESPONSE = types.ParsedResponse{
    .status = .BAD_REQUEST,
    .contentType = .JSON,
    .returnData = "{\"error\":\"invalid request\"}",
};

pub fn httpListener(io: *const std.Io, gpa: *const std.mem.Allocator) void {
    var db = DB.new("postgresql://zerefdegnl@localhost:5432/myapp", gpa.*, io.*) catch {
        print("Failed to connect to DB\n", .{});
        return;
    };

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

        var reader_buf: [BUF_LIMIT]u8 = undefined;
        var writer_buf: [BUF_LIMIT]u8 = undefined;

        for (&reader_buf, &writer_buf) |*item1, *item2| {
            item1.* = 0;
            item2.* = 0;
        }

        var client_reader = client.reader(io.*, reader_buf[0..]);
        var client_writer = client.writer(io.*, writer_buf[0..]);

        var user_data_buf: [BUF_LIMIT]u8 = undefined;
        var parser = Parser{ .reader = &client_reader.interface, .writer = &client_writer.interface, .user_data_buf = &user_data_buf };
        const parsedRequest = parser.parseRequest();

        var responseBuffer: [BUF_LIMIT]u8 = undefined;
        if (!parsedRequest.allRequiredSet()) {
            const wireResponse = BAD_REQUEST_RESPONSE.createResponseWire(&responseBuffer) catch continue;
            parser.sendBackRespone(wireResponse);
            continue;
        }

        // Holds the dynamic response body (e.g. the fetched phone number).
        // Must outlive `response`, since `response.returnData` may borrow from it.
        var body_buf: [BUF_LIMIT]u8 = undefined;

        const response = switch (parsedRequest.route.?) {
            Routes.ROOT => routes.root.handleRootCall(io.*, &body_buf) catch BAD_REQUEST_RESPONSE,
            Routes.GET_CONTACT => routes.getContact.handleGetContact(&parsedRequest, &db, &body_buf) catch BAD_REQUEST_RESPONSE,
            Routes.UPLOAD_CONTACT => routes.uploadContact.handleUploadContact(&parsedRequest, &db) catch BAD_REQUEST_RESPONSE,
            Routes.UPDATE_CONTACT => routes.updateContact.handleUpdateContact(&parsedRequest, &db) catch BAD_REQUEST_RESPONSE,
            Routes.DELETE_CONTACT => routes.delContact.handleDelContact(&parsedRequest, &db) catch BAD_REQUEST_RESPONSE,
        };

        const wireResponse = response.createResponseWire(&responseBuffer) catch |err| {
            print("Failed to build response: {}\n", .{err});
            continue;
        };

        parser.sendBackRespone(wireResponse);
    }
}
