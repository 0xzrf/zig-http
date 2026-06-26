const std = @import("std");
const types = @import("../types.zig");
const ContentType = types.ContentType;
const ParsedResponse = types.ParsedResponse;
const RequestErrors = types.RequestErrors;
const StatusCode = types.StatusCode;

pub fn handleRootCall(io: std.Io, body_buf: []u8) RequestErrors!ParsedResponse {
    const html = std.Io.Dir.cwd().readFile(io, "fe/index.html", body_buf) catch return RequestErrors.ServerError;

    return ParsedResponse{ .status = StatusCode.OK, .contentType = ContentType.HTML, .returnData = html };
}
