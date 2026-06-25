//! This file will be used to parse the incoming request from the http parser
//! and convert it into usable data, and convert it back to the wire format

const std = @import("std");
const print = std.debug.print;

pub const Parser = struct {
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,

    pub fn parseRequest(self: *Parser) void {
        var reader = self.*.reader;

        while (reader.takeDelimiter('\n') catch |err|
            {
                print("Unable to take delimiter: {}\n", .{err});
                return;
            }) |line|
        {
            print("recv {d} bytes: {s}\n", .{ line.len, line });
        }
    }
};
