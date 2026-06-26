const DB = @import("../db.zig").DB;
const types = @import("../types.zig");

const RequestErrors = types.RequestErrors;
const ParsedResponse = types.ParsedResponse;
const ParsedRequest = types.ParsedRequest;
const StatusCode = types.StatusCode;
const ContentType = types.ContentType;

pub fn handleGetContact(parsedRequest: *const ParsedRequest, db: *DB) RequestErrors!ParsedResponse {
    if (parsedRequest.*.method.? != types.Methods.GET) {
        return RequestErrors.InvalidMethod;
    }

    // since we expect only contact to be there, we can directly send parsedRequest.userData as is
    // user_data == null checked during parsing
    const ph = db.fetchContact(parsedRequest.user_data.?) catch return RequestErrors.InvalidMethod;
    defer db.*.allocator.free(ph); // required to avoid memory leaks

    const returnData: [15]u8 = undefined;
    @import("std").fmt.bufPrint(
        returnData,
        "{ \"ph\": {s} }",
        .{ph},
    );

    return ParsedResponse{ .contentType = ContentType.JSON, .returnData = returnData, .status = StatusCode.OK };
}
