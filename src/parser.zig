//! This file will be used to parse the incoming request from the http parser
//! and convert it into usable data, and convert it back to the wire format

const std = @import("std");
const types = @import("types.zig");
const routes = @import("routes/mod.zig");

const ParsedRequest = types.ParsedRequest;
const Methods = types.Methods;
const Routes = types.Routes;

pub const Parser = struct {
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,

    const startsWith = std.mem.startsWith;
    const contains = std.mem.indexOf;
    const print = std.debug.print;

    pub fn parseRequest(self: *Parser) !ParsedRequest {
        var reader = self.*.reader;
        var request = ParsedRequest.new();

        // for now, we're reading each line. We can extend Parser.extractField to support more options
        // like checking for body content as valid if the request says `Content-Type: json` or something
        while (reader.takeDelimiter('\n') catch |err|
            {
                print("Unable to take delimiter: {}\n", .{err});
                return;
            }) |line| // this line should be each line, with ending \n excluded(every line in an http header ends with \r\n)
        {
            Parser.extractField(line, &request);

            // if the values are set, then break
            if (request.allRequiredSet()) {
                break;
            }
        }

        if (request.allRequiredSet()) {
            return request;
        }
    }

    fn extractField(line: []const u8, req: *ParsedRequest) void {
        Parser.extractMethod(line, req);
        Parser.extractRoute(line, req);
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
    const request = "GET /get-contact HTTP/1.1\r\n";

    Parser.extractField(request, &requestParser);
    try expectEqual(requestParser.method, Methods.GET);

    try expectEqual(requestParser.route, Routes.GET_CONTACT);
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
