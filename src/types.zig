//! Defines different types used accross the project
const std = @import("std");

pub const Methods = enum { GET, PUT, POST, DELETE };
pub const StatusCode = enum(u16) { OK = 200, CREATED = 201, BAD_REQUEST = 400, UNAUTHORIZED = 401, NOT_FOUND = 404, METHOD_NOT_ALLOWED = 405, INTERNAL_SERVER_ERROR = 500, NOT_IMPLEMENTED = 501 };

pub const RequestErrors = error{
    InvalidMethod,
};

pub const Routes = enum { GET_CONTACT, UPDATE_CONTACT, UPLOAD_CONTACT, DELETE_CONTACT, ROOT };
pub const ContentType = enum { HTML, JSON };

// the user data will be an array of bytes, which the parser will serialize in order that the route struct will expect
pub const ParsedRequest = struct {
    route: ?Routes,
    method: ?Methods,
    user_data: ?[]u8,

    pub fn new() ParsedRequest {
        return ParsedRequest{ .route = null, .method = null, .user_data = null };
    }

    pub fn allRequiredSet(self: *const ParsedRequest) bool {
        return (self.*.route != null and self.*.method != null);
    }

    pub fn setRoute(self: *ParsedRequest, route: Routes) void {
        self.*.route = route;
    }

    pub fn setMethod(self: *ParsedRequest, method: Methods) void {
        self.*.method = method;
    }
};

pub fn contentTypeBytes(contentType: ContentType) []const u8 {
    return switch (contentType) {
        ContentType.HTML => "text/html",
        ContentType.JSON => "application/json",
    };
}

pub fn statusCodeBytes(status: StatusCode) []const u8 {
    return switch (status) {
        StatusCode.OK => "200 OK",
        StatusCode.CREATED => "201 Created",
        StatusCode.BAD_REQUEST => "400 Bad Request",
        StatusCode.UNAUTHORIZED => "401 Unauthorized",
        StatusCode.NOT_FOUND => "404 Not Found",
        StatusCode.METHOD_NOT_ALLOWED => "405 Method Not Allowed",
        StatusCode.INTERNAL_SERVER_ERROR => "500 Internal Server Error",
        StatusCode.NOT_IMPLEMENTED => "501 Not Implemented",
    };
}

pub const ParsedResponse = struct {
    status: StatusCode,
    contentType: ContentType,
    returnData: []const u8,

    pub fn createResponseWire(self: ParsedResponse, buf: []u8) ![]u8 {
        return std.fmt.bufPrint(
            buf,
            "HTTP/1.1 {s}\r\nContent-Type: {s}\r\nContent-Length: {d}\r\n\r\n{s}",
            .{
                statusCodeBytes(self.status),
                contentTypeBytes(self.contentType),
                self.returnData.len,
                self.returnData,
            },
        );
    }
};
