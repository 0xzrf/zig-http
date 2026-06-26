const DB = @import("../db.zig").DB;
const types = @import("../types.zig");
const ParsedResponse = types.ParsedResponse;
const StatusCode = types.StatusCode;
const ContentType = types.ContentType;

pub fn handleGetContact() ParsedResponse {
    const html = "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>Hello World</title></head><body><h1>Hello, World!</h1></body></html>";

    return ParsedResponse{ .status = StatusCode.OK, .contentType = ContentType.HTML, .returnData = html };
}
