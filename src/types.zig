//! Defines different types used accross the project
pub const Methods = enum { GET, PUT, POST, DELETE };
pub const StatusCode = enum(u16) { OK = 200, CREATED, BAD_REQUEST = 400, UNAUTHORIZED, NOT_FOUND, METHOD_NOT_ALLOWED, INTERNAL_SERVER_ERROR = 500, NOT_IMPLEMENTED };

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

    pub fn allRequiredSet(self: *ParsedRequest) bool {
        return (self.*.route != null and self.*.method != null);
    }

    pub fn setRoute(self: *ParsedRequest, route: Routes) void {
        self.*.route = route;
    }

    pub fn setMethod(self: *ParsedRequest, method: Methods) void {
        self.*.method = method;
    }
};

pub const ParsedResponse = struct {
    status: StatusCode,
    contentType: ContentType,
    return_data: []u8,
};
