const std = @import("std");
const Package = @import("../commons/package.zig").Package;
const BuilderContext = @import("../builder/interpreter.zig").BuilderContext;
const edu = @import("../commons/edu_language.zig");
const downloader = @import("../commons/downloader.zig");

// TODO: Remove this and use github as host
const packages = [_]Package{
    Package{ .name = "hello-world", .source = 
    \\var package_name = "hello-world";
    \\var package_version = "0.0.1";
    \\
    \\fn install() {
    \\  $echo "hello, world :)"
    \\  $ls
    \\  $touch test.txt
    \\}
    \\fn uninstall() {
    \\  $rm test.txt
    \\}
    }, //
};

pub fn handlerInstall(allocator: std.mem.Allocator, value: []const u8) !bool {
    std.debug.print("Trying to find package with name: {s}\n", .{value});
    const source = try downloader.readFromURL(allocator, "");

    // comptime var idx = 0;
    // inline while (idx < packages.len) : (idx += 1) {
    //     const package = packages[idx];

    // if (std.mem.eql(u8, value, package.name)) {
    std.debug.print("Package found! Initializing...\n\n", .{});

    var context = BuilderContext.init(allocator);

    try edu.compileEduLanguage(allocator, source, &context);

    const package_name = context.getVariable("package_name") orelse return error.MissingPackageName;
    const package_version = context.getVariable("package_version") orelse return error.MissingPackageVersion;
    const install_function = context.getFunction("install") orelse return error.MissingInstallFunction;
    const uninstall_function = context.getFunction("uninstall") orelse return error.MissingInstallFunction;

    _ = package_name;
    _ = package_version;
    _ = uninstall_function;

    try install_function.execute(allocator);

    return true;
    //     }
    // }

    // return false;
}
