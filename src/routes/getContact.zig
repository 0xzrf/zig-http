const std = @import("std");
const DB = @import("../db.zig").DB;
const types = @import("../types.zig");

const RequestErrors = types.RequestErrors;
const ParsedResponse = types.ParsedResponse;
const ParsedRequest = types.ParsedRequest;
const StatusCode = types.StatusCode;
const ContentType = types.ContentType;

/// GET /get-contact?name=<contact>
/// `user_data` is the contact name as-is.
/// `body_buf` is owned by the caller and must outlive the returned response,
/// since `returnData` borrows from it.
pub fn handleGetContact(parsedRequest: *const ParsedRequest, db: *DB, body_buf: []u8) RequestErrors!ParsedResponse {
    if (parsedRequest.method.? != types.Methods.GET) {
        return RequestErrors.InvalidMethod;
    }

    const contact = parsedRequest.user_data orelse return RequestErrors.InvalidPayload;

    // fetchContact allocates an owned copy, so we must free it before returning.
    const ph = db.fetchContact(contact) catch return RequestErrors.NotFound;
    defer db.allocator.free(ph);

    const body = std.fmt.bufPrint(body_buf, "{{\"ph\":\"{s}\"}}", .{ph}) catch return RequestErrors.ServerError;

    return ParsedResponse{ .status = StatusCode.OK, .contentType = ContentType.JSON, .returnData = body };
}
