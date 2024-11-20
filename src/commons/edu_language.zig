const std = @import("std");
const Lexer = @import("../builder/lexer.zig").Lexer;
const Token = @import("../builder/lexer.zig").Token;
const Parser = @import("../builder/parser.zig").Parser;
const Interpreter = @import("../builder/interpreter.zig").Interpreter;
const BuilderContext = @import("../builder/interpreter.zig").BuilderContext;

pub fn compileEduLanguage(allocator: std.mem.Allocator, source: []const u8, context: *BuilderContext) !void {
    var lexer = Lexer.init(source);
    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    while (lexer.nextToken()) |token| {
        try tokens.append(token);
    }

    var parser = Parser.init(&tokens.items);
    var interpreter = Interpreter.init(context);

    while (true) {
        const node = try parser.parse(allocator) orelse break;
        try interpreter.execute(node);
    }
}
