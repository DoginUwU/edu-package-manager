const std = @import("std");
const Token = @import("lexer.zig").Token;
const TokenType = @import("lexer.zig").TokenType;

const NodeType = enum {
    VariableDeclaration,
    FunctionDeclaration,
    CodeDeclaration,
    Literal,
};

pub const Node = struct {
    type: NodeType,
    children: ?[]const Node,
    value: []const u8,

    pub fn execute(self: *const Node, allocator: std.mem.Allocator) !void {
        switch (self.type) {
            .FunctionDeclaration => {
                if (self.children) |children| {
                    for (children) |child| {
                        try child.execute(allocator);
                    }
                }
            },
            .CodeDeclaration => {
                if (self.value.len == 0) {
                    return error.InvalidValueCodeDeclaration;
                }

                std.debug.print("COMMAND EXECUTE => {s}\n", .{self.value});

                var arg_parts = std.mem.split(u8, self.value, " ");
                var args = std.ArrayList([]const u8).init(allocator);
                defer args.deinit();

                while (arg_parts.next()) |arg| {
                    try args.append(arg);
                }

                var process = std.process.Child.init(args.items, allocator);
                process.stdout_behavior = .Pipe;
                process.stderr_behavior = .Pipe;

                var stdout = std.ArrayList(u8).init(allocator);
                var stderr = std.ArrayList(u8).init(allocator);
                defer {
                    stdout.deinit();
                    stderr.deinit();
                }

                try process.spawn();
                try process.collectOutput(&stdout, &stderr, 1024);
                const term = try process.wait();

                if (term.Exited == 0) {
                    std.debug.print("COMMAND OUTPUT => {s}\n", .{stdout.items});
                } else {
                    std.debug.print("COMMAND FAILED => {s}\n", .{stderr.items});
                }
            },
            else => return,
        }
    }
};

pub const Parser = struct {
    tokens: *[]const Token,
    position: usize,

    pub fn init(tokens: *[]const Token) Parser {
        return Parser{
            .tokens = tokens,
            .position = 0,
        };
    }

    fn peek(self: *const Parser) ?Token {
        if (self.position < self.tokens.len) {
            return self.tokens.ptr[self.position];
        }

        return null;
    }

    fn next(self: *Parser) ?Token {
        const current_token = self.peek() orelse return null;

        self.position += 1;

        return current_token;
    }

    fn expect(self: *Parser, token_type: TokenType) !Token {
        const token = self.peek() orelse return error.MissingToken;

        if (token.type != token_type) {
            return error.InvalidTokenType;
        }

        _ = self.next();
        return token;
    }

    fn parseVariableDeclaration(self: *Parser) !Node {
        _ = try self.expect(.Var);
        const identifier = try self.expect(.Identifier);
        _ = try self.expect(.Equals);

        const value = self.peek() orelse return error.ExpectedToken;
        _ = self.next();
        _ = try self.expect(.Semicolon);

        var children = [_]Node{
            Node{ //
                .type = .Literal,
                .value = identifier.value,
                .children = null,
            },
            Node{
                .type = .Literal,
                .value = value.value,
                .children = null,
            },
        };

        return Node{
            .type = .VariableDeclaration,
            .value = identifier.value,
            .children = children[0..],
        };
    }

    fn parseCodeDeclaration(self: *Parser) !Node {
        const value = try self.expect(.Code);

        return Node{
            .type = .CodeDeclaration,
            .value = value.value,
            .children = null,
        };
    }

    fn parseFunctionDeclaration(self: *Parser, allocator: std.mem.Allocator) !Node {
        _ = try self.expect(.Function);
        const identifier = try self.expect(.Identifier);
        _ = try self.expect(.OpenParen);
        _ = try self.expect(.CloseParen);
        _ = try self.expect(.OpenBracket);

        var children = std.ArrayList(Node).init(allocator);
        errdefer children.deinit();

        while (true) {
            const token = self.peek() orelse break;
            if (token.type == .CloseBracket) break;

            const node = try self.parseFunctionStatement();

            try children.append(node);
        }

        _ = try self.expect(.CloseBracket);

        return Node{
            .type = .FunctionDeclaration,
            .value = identifier.value,
            .children = children.items,
        };
    }

    fn parseFunctionStatement(self: *Parser) !Node {
        const token = self.peek() orelse return error.ExpectedToken;

        switch (token.type) {
            .Var => return try self.parseVariableDeclaration(),
            .Code => return try self.parseCodeDeclaration(),
            else => return error.UnexpectedToken,
        }
    }

    pub fn parse(self: *Parser, allocator: std.mem.Allocator) !?Node {
        const token = self.peek() orelse return null;

        switch (token.type) {
            .Var => return try self.parseVariableDeclaration(),
            .Function => return try self.parseFunctionDeclaration(allocator),
            else => return error.UnexpectedToken,
        }
    }
};
