const std = @import("std");
const http_io = @import("http_io.zig");

pub fn main(init: std.process.Init) void {
    http_io.httpListener(&init.io);
}
