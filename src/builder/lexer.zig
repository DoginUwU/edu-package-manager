const std = @import("std");

pub const TokenType = enum {
    Var,
    Code,
    Identifier,
    Equals,
    String,
    Semicolon,
    Function,
    OpenParen,
    CloseParen,
    OpenBracket,
    CloseBracket,
    Unknown,
};

pub const Token = struct {
    type: TokenType,
    value: []const u8,
};

pub const Lexer = struct {
    source: []const u8,
    position: usize,
    row: usize,
    column: usize,

    pub fn init(source: []const u8) Lexer {
        return Lexer{ .source = source, .position = 0, .row = 0, .column = 0 };
    }

    fn peek(self: *const Lexer) ?u8 {
        if (self.position < self.source.len) {
            return self.source[self.position];
        }

        return null;
    }

    fn next(self: *Lexer) ?u8 {
        const current_char = self.peek();

        if (current_char != null) {
            self.position += 1;

            if (current_char == '\n') {
                self.row += 1;
                self.column = 0;
            } else {
                self.column += 1;
            }
        }

        return current_char;
    }

    fn ignoreWhitespaces(self: *Lexer) void {
        while (self.peek()) |current| {
            switch (current) {
                '\n' => {
                    _ = self.next();
                },
                '\t' => {
                    _ = self.next();
                },
                ' ' => {
                    _ = self.next();
                },
                else => break,
            }
        }
    }

    pub fn nextToken(self: *Lexer) ?Token {
        self.ignoreWhitespaces();
        var current = self.next();

        var start_position = self.position;
        // const start_row = self.row;
        // const start_column = self.column;

        while (current == ' ') {
            current = self.next();
        }

        if (current) |char| {
            switch (char) {
                'a'...'z' => {
                    self.position -= 1;
                    start_position = self.position;

                    while (self.peek() != null and self.peek() != ' ' and self.peek() != '(') {
                        _ = self.next();
                    }

                    const value = self.source[start_position..self.position];

                    if (std.mem.eql(u8, value, "var")) {
                        return Token{ .type = .Var, .value = value };
                    }

                    if (std.mem.eql(u8, value, "fn")) {
                        return Token{ .type = .Function, .value = value };
                    }

                    return Token{ .type = .Identifier, .value = value };
                },
                '$' => {
                    while (self.peek() != null and self.peek() != '\n') {
                        _ = self.next();
                    }
                    const value = self.source[start_position..self.position];
                    return Token{ .type = .Code, .value = value };
                },
                '=' => {
                    return Token{ .type = .Equals, .value = "=" };
                },
                '"' => {
                    while (self.peek() != null and self.peek() != '"') {
                        _ = self.next();
                    }

                    if (self.peek() == '"') {
                        const value = self.source[start_position..self.position];
                        _ = self.next();
                        return Token{ .type = .String, .value = value };
                    } else {
                        @panic("String literal not terminated");
                    }
                },
                ';' => {
                    return Token{ .type = .Semicolon, .value = ";" };
                },
                '(' => {
                    return Token{ .type = .OpenParen, .value = "(" };
                },
                ')' => {
                    return Token{ .type = .CloseParen, .value = ")" };
                },
                '{' => {
                    return Token{ .type = .OpenBracket, .value = "{" };
                },
                '}' => {
                    return Token{ .type = .CloseBracket, .value = "}" };
                },
                else => {
                    return Token{
                        .type = .Unknown, //
                        .value = self.source[start_position..self.position],
                    };
                },
            }
        }

        return null;
    }
};
