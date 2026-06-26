const DB = @import("../db.zig").DB;
const types = @import("../types.zig");

const RequestErrors = types.RequestErrors;
const ParsedResponse = types.ParsedResponse;
const ParsedRequest = types.ParsedRequest;
const StatusCode = types.StatusCode;
const ContentType = types.ContentType;

/// DELETE /delete-contact?name=<contact>
/// `user_data` is the contact name as-is (only a contact is needed to delete).
pub fn handleDelContact(parsedRequest: *const ParsedRequest, db: *DB) RequestErrors!ParsedResponse {
    if (parsedRequest.method.? != types.Methods.DELETE) {
        return RequestErrors.InvalidMethod;
    }

    const contact = parsedRequest.user_data orelse return RequestErrors.InvalidPayload;

    db.delContact(contact) catch return RequestErrors.NotFound;

    return ParsedResponse{ .status = StatusCode.OK, .contentType = ContentType.JSON, .returnData = "{\"status\":\"deleted\"}" };
}
