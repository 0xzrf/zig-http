//! This is the main orchestrator of the http server
//! It'll start listening on port 8888, listen to the incoming packets on the server
//! then send it to the parser to get the appropriate method + route for it,
//! build a response for the request, and finally send back the appropriate respone

const std = @import("std");

pub fn main() void {
    std.debug.print("Hello World!\nI'm {s}, and I'm {} y/o\n", .{ "Zeref", 20 });

    std.http.Client.connect(std.http.Client, host: HostName, port: u16, protocol: Protocol);
}
