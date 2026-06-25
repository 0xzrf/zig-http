//! This is the main orchestrator of the http server
//! It'll start listening on port 8888, listen to the incoming packets on the server
//! then send it to the parser to get the appropriate method + route for it,
//! build a response for the request, and finally send back the appropriate respone

const std = @import("std");
const http_io = @import("http_io.zig");

pub fn main(init: std.process.Init) void {
    http_io.http_listener(&init.io);
}
