const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const http_io_lib = b.addLibrary(.{
        .name = "http_io",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/http_io.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const exe = b.addExecutable(.{
        .name = "zig-http",
        .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize }),
    });

    exe.root_module.linkLibrary(http_io_lib);

    b.installArtifact(http_io_lib);
    b.installArtifact(exe);
}
