//! This file will be used to parse the incoming request from the http parser
//! and convert it into usable data, and convert it back to the wire format

const std = @import("std");
const types = @import("types.zig");

const ParsedRequest = types.ParsedRequest;
const Methods = types.Methods;
const Routes = types.Routes;

pub const Parser = struct {
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    user_data_buf: []u8,

    const startsWith = std.mem.startsWith;
    const contains = std.mem.indexOf;
    const print = std.debug.print;

    pub fn parseRequest(self: *Parser) ParsedRequest {
        var reader = self.*.reader;
        var request = ParsedRequest.new();
        var content_length: ?usize = null;

        // Read the request line and headers. The first empty line marks the end of
        // the header section; if Content-Length exists, the body starts after it.
        while (reader.takeDelimiter('\n') catch |err|
            {
                print("Unable to take delimiter: {}\n", .{err});
                return request;
            }) |line| // this line should be each line, with ending \n excluded(every line in an http header ends with \r\n)
        {
            const trimmed_line = std.mem.trim(u8, line, "\r");
            if (trimmed_line.len == 0) {
                break;
            }

            Parser.extractField(trimmed_line, &request);

            if (Parser.parseContentLength(trimmed_line)) |len| {
                content_length = len;
            }
        }

        if (!request.allRequiredSet()) {
            return request;
        }

        switch (request.route.?) {
            .UPLOAD_CONTACT, .UPDATE_CONTACT, .DELETE_CONTACT => {
                const len = content_length orelse return request;
                const body = reader.take(len) catch |err| {
                    print("Unable to read request body: {}\n", .{err});
                    return request;
                };

                Parser.populateBodyUserData(self.user_data_buf, body, &request) catch {
                    return request;
                };
            },
            else => {},
        }

        return request;
    }

    pub fn sendBackRespone(self: *Parser, data: []const u8) void {
        self.*.writer.writeAll(data) catch |err| print("Error occured while writing to the write: {}\n", .{err});
        self.*.writer.flush() catch |err| print("Couldn't flush\n{}", .{err});
    }

    fn extractField(line: []const u8, req: *ParsedRequest) void {
        Parser.extractMethod(line, req);
        Parser.extractRoute(line, req);
    }

    fn parseContentLength(line: []const u8) ?usize {
        const prefix = "Content-Length:";
        if (line.len < prefix.len) return null;
        if (!std.ascii.eqlIgnoreCase(line[0..prefix.len], prefix)) return null;

        const value = std.mem.trim(u8, line[prefix.len..], " \t");
        return std.fmt.parseInt(usize, value, 10) catch null;
    }

    fn queryParam(line: []const u8, key: []const u8) ?[]const u8 {
        const query_start = contains(u8, line, "?") orelse return null;
        const target_end = contains(u8, line[query_start + 1 ..], " ") orelse return null;
        return Parser.paramValue(line[query_start + 1 .. query_start + 1 + target_end], key);
    }

    fn bodyParam(body: []const u8, key: []const u8) ?[]const u8 {
        return Parser.paramValue(body, key);
    }

    fn paramValue(params: []const u8, key: []const u8) ?[]const u8 {
        var parts = std.mem.splitScalar(u8, params, '&');
        while (parts.next()) |part| {
            const eq_idx = contains(u8, part, "=") orelse continue;
            const param_key = part[0..eq_idx];
            if (std.mem.eql(u8, param_key, key)) {
                return part[eq_idx + 1 ..];
            }
        }

        return null;
    }

    fn populateBodyUserData(buf: []u8, body: []const u8, req: *ParsedRequest) !void {
        switch (req.route.?) {
            .UPLOAD_CONTACT, .UPDATE_CONTACT => {
                const contact = Parser.bodyParam(body, "contact") orelse return error.InvalidPayload;
                const ph = Parser.bodyParam(body, "ph") orelse return error.InvalidPayload;

                if (contact.len > std.math.maxInt(u8) or ph.len > std.math.maxInt(u8)) {
                    return error.InvalidPayload;
                }
                if (buf.len < contact.len + ph.len + 2) {
                    return error.InvalidPayload;
                }

                buf[0] = @intCast(contact.len);
                @memcpy(buf[1 .. 1 + contact.len], contact);

                const ph_len_idx = 1 + contact.len;
                buf[ph_len_idx] = @intCast(ph.len);
                @memcpy(buf[ph_len_idx + 1 .. ph_len_idx + 1 + ph.len], ph);

                req.setUserData(buf[0 .. ph_len_idx + 1 + ph.len]);
            },
            .DELETE_CONTACT => {
                const contact = Parser.bodyParam(body, "contact") orelse return error.InvalidPayload;
                req.setUserData(contact);
            },
            else => {},
        }
    }

    fn extractMethod(line: []const u8, req: *ParsedRequest) void {
        if (startsWith(u8, line, "GET")) {
            req.setMethod(Methods.GET);
        }
        if (startsWith(u8, line, "POST")) {
            req.setMethod(Methods.POST);
        }
        if (startsWith(u8, line, "PUT")) {
            req.setMethod(Methods.PUT);
        }
        if (startsWith(u8, line, "DELETE")) {
            req.setMethod(Methods.DELETE);
        }
    }

    fn extractRoute(line: []const u8, req: *ParsedRequest) void {
        if (contains(u8, line, "/get-contact") != null) {
            req.setRoute(Routes.GET_CONTACT);
            if (Parser.queryParam(line, "contact")) |contact| {
                req.setUserData(contact);
            }
        }
        if (contains(u8, line, "/upload-contact") != null) {
            req.setRoute(Routes.UPLOAD_CONTACT);
        }
        if (contains(u8, line, "/update-contact") != null) {
            req.setRoute(Routes.UPDATE_CONTACT);
        }
        if (contains(u8, line, "/delete-contact") != null) {
            req.setRoute(Routes.DELETE_CONTACT);
        }
        if (contains(u8, line, "/ ") != null) {
            req.setRoute(Routes.ROOT);
        }
    }
};

test "GET / parses correctly" {
    const expectEqual = std.testing.expectEqual;

    var requestParser = ParsedRequest.new();
    const request = "GET / HTTP/1.1\r\n";

    Parser.extractField(request, &requestParser);

    try expectEqual(requestParser.method, Methods.GET);

    try expectEqual(requestParser.route, Routes.ROOT);
}

test "GET /get-contact parses correctly" {
    const expectEqual = std.testing.expectEqual;

    var requestParser = ParsedRequest.new();
    const request = "GET /get-contact?contact=Zeref HTTP/1.1\r\n";

    Parser.extractField(request, &requestParser);
    try expectEqual(requestParser.method, Methods.GET);

    try expectEqual(requestParser.route, Routes.GET_CONTACT);
    try std.testing.expectEqualStrings("Zeref", requestParser.user_data.?);
}

test "POST /upload-contact parses correctly" {
    const expectEqual = std.testing.expectEqual;

    var requestParser = ParsedRequest.new();
    const request = "POST /upload-contact HTTP/1.1\r\n";

    Parser.extractField(request, &requestParser);
    try expectEqual(requestParser.method, Methods.POST);

    try expectEqual(requestParser.route, Routes.UPLOAD_CONTACT);
}

test "PUT /update-contact parses correctly" {
    const expectEqual = std.testing.expectEqual;

    var requestParser = ParsedRequest.new();
    const request = "PUT /update-contact HTTP/1.1\r\n";

    Parser.extractField(request, &requestParser);
    try expectEqual(requestParser.method, Methods.PUT);

    try expectEqual(requestParser.route, Routes.UPDATE_CONTACT);
}

test "DELETE /delete-contact parses correctly" {
    const expectEqual = std.testing.expectEqual;

    var requestParser = ParsedRequest.new();
    const request = "DELETE /delete-contact HTTP/1.1\r\n";

    Parser.extractField(request, &requestParser);
    try expectEqual(requestParser.method, Methods.DELETE);

    try expectEqual(requestParser.route, Routes.DELETE_CONTACT);
}

test "POST /upload-contact body populates length-prefixed user_data" {
    var requestParser = ParsedRequest.new();
    requestParser.setRoute(Routes.UPLOAD_CONTACT);

    var buf: [64]u8 = undefined;
    try Parser.populateBodyUserData(&buf, "contact=Zeref&ph=12345", &requestParser);

    const data = requestParser.user_data.?;
    try std.testing.expectEqual(@as(u8, 5), data[0]);
    try std.testing.expectEqualStrings("Zeref", data[1..6]);
    try std.testing.expectEqual(@as(u8, 5), data[6]);
    try std.testing.expectEqualStrings("12345", data[7..12]);
}

test "PUT /update-contact body requires contact and ph" {
    var requestParser = ParsedRequest.new();
    requestParser.setRoute(Routes.UPDATE_CONTACT);

    var buf: [64]u8 = undefined;
    try std.testing.expectError(error.InvalidPayload, Parser.populateBodyUserData(&buf, "contact=Zeref", &requestParser));
}

test "DELETE /delete-contact body populates contact user_data" {
    var requestParser = ParsedRequest.new();
    requestParser.setRoute(Routes.DELETE_CONTACT);

    var buf: [64]u8 = undefined;
    try Parser.populateBodyUserData(&buf, "contact=Zeref", &requestParser);

    try std.testing.expectEqualStrings("Zeref", requestParser.user_data.?);
}
