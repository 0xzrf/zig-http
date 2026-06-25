//! Defines different types used accross the project
const Methods = enum { GET, PUT, PUSH, DELETE };
const StatusCode = enum(u16) { OK = 200, CREATED, BAD_REQUEST = 400, UNAUTHORIZED, NOT_FOUND, METHOD_NOT_ALLOWED, INTERNAL_SERVER_ERROR = 500, NOT_IMPLEMENTED };

const Routes = enum { GET_CONTACT, UPDATE_CONTACT, UPLOAD_CONTACT, DELETE_CONTACT };

// the user data will be an array of bytes, which the parser will serialize in order that the route struct will expect
const ParsedStruct = struct { route: Routes, method: Methods, user_data: []u8 };
