const std = @import("std");
const handlerInstall = @import("commands/install.zig").handlerInstall;
const handlerUninstall = @import("commands/uninstall.zig").handlerUninstall;

const Command = struct {
    name: []const u8,
    function: fn (std.mem.Allocator, []const u8) anyerror!bool,
};

pub const commands = [_]Command{
    Command{ .name = "install", .function = handlerInstall }, //
    Command{ .name = "uninstall", .function = handlerUninstall },
};

pub fn handleCliArguments(alloc: std.mem.Allocator) !void {
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    while (args.next()) |arg| {
        comptime var idx = 0;

        inline while (idx < commands.len) : (idx += 1) {
            const command = commands[idx];
            if (std.mem.eql(u8, arg, command.name)) {
                const value = args.next() orelse return error.MissingArgValue;

                if (!try command.function(alloc, value)) {
                    return error.FailedToExecuteCommand;
                }

                return;
            }
        }
    }

    return error.ArgNotFound;
}
