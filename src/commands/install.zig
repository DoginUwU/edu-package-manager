const std = @import("std");
const Package = @import("../commons/package.zig").Package;
const BuilderContext = @import("../builder/interpreter.zig").BuilderContext;
const edu = @import("../commons/edu_language.zig");
const downloader = @import("../commons/downloader.zig");

pub fn handlerInstall(allocator: std.mem.Allocator, value: []const u8) !bool {
    std.debug.print("Trying to find package with name: {s}\n", .{value});

    var url = std.ArrayList(u8).init(allocator);
    defer url.deinit();

    try url.appendSlice("https://raw.githubusercontent.com/DoginUwU/edu-package-manager/refs/heads/main/packages/");
    try url.appendSlice(value);
    try url.appendSlice("/build.edu");

    const source = try downloader.readFromURL(allocator, url.items);

    std.debug.print("Package found! Initializing...\n\n", .{});

    var context = BuilderContext.init(allocator);

    try edu.compileEduLanguage(allocator, source, &context);

    const package_name = context.getVariable("package_name") orelse return error.MissingPackageName;
    const package_version = context.getVariable("package_version") orelse return error.MissingPackageVersion;
    const install_function = context.getFunction("install") orelse return error.MissingInstallFunction;
    const uninstall_function = context.getFunction("uninstall") orelse return error.MissingInstallFunction;

    if (!std.mem.eql(u8, package_name, value)) {
        return error.PackageNameConflict;
    }

    _ = package_version;
    _ = uninstall_function;

    try install_function.execute(allocator);

    return true;
}
