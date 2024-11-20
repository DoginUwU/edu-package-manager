const std = @import("std");
const Node = @import("parser.zig").Node;

const NodeHashMap = struct {};

pub const BuilderContext = struct {
    variables: std.hash_map.StringHashMap([]const u8),
    functions: std.hash_map.StringHashMap(Node),

    pub fn init(allocator: std.mem.Allocator) BuilderContext {
        var variables = std.StringHashMap([]const u8).init(allocator);
        defer variables.deinit();
        var functions = std.StringHashMap(Node).init(allocator);
        defer functions.deinit();

        return BuilderContext{
            .variables = variables,
            .functions = functions,
        };
    }

    pub fn setVariable(self: *BuilderContext, key: []const u8, value: []const u8) !void {
        try self.variables.put(key, value);
    }

    pub fn getVariable(self: *BuilderContext, key: []const u8) ?[]const u8 {
        return self.variables.get(key);
    }

    pub fn setFunction(self: *BuilderContext, key: []const u8, value: Node) !void {
        try self.functions.put(key, value);
    }

    pub fn getFunction(self: *BuilderContext, key: []const u8) ?Node {
        return self.functions.get(key);
    }
};

pub const Interpreter = struct {
    context: *BuilderContext,

    pub fn init(context: *BuilderContext) Interpreter {
        return Interpreter{
            .context = context,
        };
    }

    pub fn execute(self: *Interpreter, node: Node) !void {
        switch (node.type) {
            .VariableDeclaration => try self.executeVariableDeclaration(node),
            .FunctionDeclaration => try self.executeFunctionDeclaration(node),
            else => return error.InvalidNodeType,
        }
    }

    fn executeVariableDeclaration(self: *Interpreter, node: Node) !void {
        const children = node.children orelse return error.MissingChildren;
        const identifier = children.ptr[0].value;
        const value = children.ptr[1].value;

        try self.context.setVariable(identifier, value);
    }

    fn executeFunctionDeclaration(self: *Interpreter, node: Node) !void {
        try self.context.setFunction(node.value, node);
    }
};
