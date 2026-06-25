//! This file will be used to parse the incoming request from the http parser
//! and convert it into usable data, and convert it back to the wire format

const std = @import("std");
const types = @import("types.zig");

const ParsedRequest = types.ParsedRequest;
const Methods = types.Methods;

const startsWith = @import("helpers.zig").starts_with;

const print = std.debug.print;

pub const Parser = struct {
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,

    pub fn parseRequest(self: *Parser) void {
        var reader = self.*.reader;
        var request = ParsedRequest{ .method = undefined, .route = undefined, .user_data = undefined };

        while (reader.takeDelimiter('\n') catch |err|
            {
                print("Unable to take delimiter: {}\n", .{err});
                return;
            }) |line| // this line should be each line, with ending \n excluded(every line in an http header ends with \r\n)
        {
            Parser.extractField(line, &request);
        }
    }

    fn extractField(line: []u8, req: *ParsedRequest) void {
        if (startsWith(line, "GET")) {
            req.setMethod(Methods.GET);
        }
        if (startsWith(line, "POST")) {
            req.setMethod(Methods.POST);
        }
        if (startsWith(line, "PUT")) {
            req.setMethod(Methods.PUT);
        }
        if (startsWith(line, "DELETE")) {
            req.setMethod(Methods.DELETE);
        }
    }
};

// test "request" {
//     const request = "GET / HTTP/1.1\r\n";
// }
