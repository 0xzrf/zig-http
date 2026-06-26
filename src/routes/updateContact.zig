const DB = @import("../db.zig").DB;
const types = @import("../types.zig");

const RequestErrors = types.RequestErrors;
const ParsedResponse = types.ParsedResponse;
const ParsedRequest = types.ParsedRequest;
const StatusCode = types.StatusCode;
const ContentType = types.ContentType;

/// PUT /update-contact
/// Body is the length-prefixed payload: [contact_len][contact][phone_len][phone]
pub fn handleUpdateContact(parsedRequest: *const ParsedRequest, db: *DB) RequestErrors!ParsedResponse {
    if (parsedRequest.method.? != types.Methods.PUT) {
        return RequestErrors.InvalidMethod;
    }

    const data = parsedRequest.user_data orelse return RequestErrors.InvalidPayload;
    const parsed = try types.decodeContactPhone(data);

    db.updateContact(parsed.contact, parsed.phone) catch return RequestErrors.NotFound;

    return ParsedResponse{ .status = StatusCode.OK, .contentType = ContentType.JSON, .returnData = "{\"status\":\"updated\"}" };
}
