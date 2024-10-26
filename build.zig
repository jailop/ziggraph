const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // const module = b.addModule("ziggraph", .{
    //    .root_source_file = b.path("src/graph.zig"),
    //    .target = target,
    //     .optimize = optimize,
    // });
    const lib = b.addStaticLibrary(.{
        .name = "ziggraph",
        .root_source_file = b.path("src/graph.zig"),
        .target = target,
        .optimize = optimize,
    });
    // lib.root_module.addImport("ziggraph", module);
    b.installArtifact(lib);
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/graph.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    const docs_step = b.step("docs", "Emit docs");
    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);
    b.default_step.dependOn(docs_step);
}
