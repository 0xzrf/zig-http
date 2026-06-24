const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOptions(.{});

    const exe = b.addExecutable(.{ .name = "http-listener", .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize });
    b.installArtifact(exe);
}
