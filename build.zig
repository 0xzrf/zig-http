const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const pgModule = b.dependency("pg", .{ .target = target, .optimize = optimize }).module("pg");

    const httpIOLib = b.addLibrary(.{
        .name = "http_io",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/http_io.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const db = b.addLibrary(.{
        .name = "db",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/db.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const exe = b.addExecutable(.{
        .name = "zig-http",
        .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize }),
    });

    db.root_module.addImport("pg", pgModule);
    httpIOLib.root_module.addImport("pg", pgModule);
    exe.root_module.linkLibrary(httpIOLib);

    const db_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/db.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    db_tests.root_module.addImport("pg", pgModule);

    const run_db_tests = b.addRunArtifact(db_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_db_tests.step);

    b.installArtifact(httpIOLib);
    b.installArtifact(exe);
}
