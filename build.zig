const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const pgModule = b.dependency("pg", .{}).module("pg");

    const httpIOLib = b.addLibrary(.{
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

    httpIOLib.root_module.addImport("pg", pgModule);

    exe.root_module.linkLibrary(httpIOLib);

    b.installArtifact(httpIOLib);
    b.installArtifact(exe);
}
