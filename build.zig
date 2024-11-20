const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "edu", //
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    exe.linkSystemLibrary("curl");
    exe.linkLibC();

    b.installArtifact(exe);
}
