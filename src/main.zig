const std = @import("std");
const cli = @import("./cli.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    try cli.handleCliArguments(alloc);
}
