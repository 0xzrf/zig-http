const std = @import("std");

pub fn main() void {
    std.debug.print("Hello World!\nI'm {s}, and I'm {} y/o\n", .{ "Zeref", 20 });
}
