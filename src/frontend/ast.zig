const std = @import("std");
const Allocator = std.mem.Allocator;

// TODO: Add better formatting with printing the AST
// TODO: Update the parser to match the new representation of the AST
// TODO: Begin work on ast -> ir AstGen

// TODO: Pretty much nuke all of this.
//
// We need a better system for generating
// IR code than this implementation of the AST.
//
// After some reading of how Zig does it, I want to settle on something less
// polymorphic. I want a polymorphic `Node` type but a concrete `AST` type that
// we generate the IR from.
//
// The concrete AST type will hold the entire AST in itself. There will only be
// one AST object for each AST. The nodes will be different, holding different
// data and a tag.
//
// Like I mentioned earlier in this rationale, the main reason for doing this
// was a lack of cohesion between the `ast` and IR types. There is no good way
// to go from an AST to a list of IR in a clean manner with how we have things
// setup now. I am really liking how the IR is represented linearly, so I do not
// want to change that. I understand that this is just the first compiler of the
// bootstrap process, so none of this code will be used once we get a working Nomi
// compiler in Nomi, so I should not worry as much about it. But this is also a learning
// experience, and I want to write good code regardless of knowing that it will
// not be used after the Nomi compiler can compile itself.

// The structure to hold the entire Abstract Syntax Tree (AST, Ast). Only one instance of
// this structure will exist for each AST, although I do not think there will be more than
// one AST at once.
//
// Just a wrapper over the `Program` type right now, but could help us later
// down the road if we decide to allocate all the different nodes on the heap
// instead of the stack. It would then be important to keep track of revelent
// information -- like the allocator used to allocate all the nodes when we go
// to deinit everything.
//
// It might seem a little backwards, but we actually want to build up the actual
// AST (starting at the Program) before passing it into the Ast instance. The point
// of the Ast type and instance is to keep track of everything after the AST has
// been built. A single Ast type also lets us do semantic analysis on it, type checking,
// easier conversion to IR, etc.
pub const Ast = struct {
    program: Program,

    pub fn init(program: Program) Ast {
        return .{
            .program = program,
        };
    }

    pub fn deinit(self: *Ast) void {
        self.program.deinit();
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{}", .{self.program});
    }
};

// Now we need to work on a pretty printer for our new AST
const pprinter = struct {
    const spaces = 2;
    var ilevel: u8 = 0; // We need to keep track of the indentation level
    // A stack to keep track of previous indentation levels

    pub fn indent(writer: anytype, add_levels: u8) !void {
        for (0..ilevel+add_levels) |_| {
            try writer.writeAll(" " ** spaces);
        }
    }

    pub fn print(writer: anytype, node: AstNode, add_levels: u8) !void {
        const level = ilevel;
        defer ilevel = level;
        ilevel += add_levels;

        try indent(writer, 0);

        try writer.print("{}", .{ node });
    }
};

// The actual node types that make up the AST
//
// When dealing with initialization and deinitialization, we pass around a
// const pointer to the AST instance. This allows us to let the AST instance
// keep track of everything and keeps everything owned by the AST.
//
// This keeps everything central and clean.

// The over arching AST `Node` type which all nodes can be represented by.
// A useful type to have when dealing with finicky things like pretty printing
pub const AstNode = union(enum) {
    program: Program,
    decl: Decl,
    stmt: Stmt,
    expr: Expr,
    
    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            inline else => |node| try writer.print("{}", .{node}),
        }
    }
};

pub const Program = struct {
    declarations: std.ArrayList(Decl),

    pub fn init(alloc: Allocator) Program {
        return .{
            .declarations = .init(alloc),
        };
    }

    pub fn deinit(self: *Program) void {
        self.declarations.deinit();
    }

    pub fn add_decl(self: *Program, decl: Decl) void {
        // TODO: Deal with this error more properly
        self.declarations.append(decl) catch unreachable;
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Program:\n", .{});
        for (self.declarations.items) |decl| {
            try pprinter.print(writer, .{ .decl = decl }, 1);
        }
    }
};

pub const Decl = union(enum) {
    func_decl: FuncDecl,

    pub fn deinit(self: *Decl) void {
        switch (self.*) {
            inline else => |decl| decl.deinit(),
        }
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            inline else => |decl| try writer.print("{}", .{decl}),
        }
    }
};

pub const FuncDecl = struct {
    name: []const u8,
    stmt: Stmt,

    pub fn init(name: []const u8, stmt: Stmt) FuncDecl {
        return .{
            .name = name,
            .stmt = stmt,
        };
    }

    pub fn deinit(_: *FuncDecl) void {}

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("FuncDecl:\n", .{});

        try pprinter.indent(writer, 1);
        try writer.print("Name:\n", .{});

        try pprinter.indent(writer, 2);
        try writer.print("{s}\n", .{self.name});

        try pprinter.indent(writer, 1);
        try writer.print("Body:\n", .{});

        try pprinter.print(writer, .{.stmt = self.stmt}, 2);
    }
};

pub const Stmt = union(enum) {
    block: Block,
    ret: Return,
    expr: Expr,

    pub fn deinit(self: *Stmt) void {
        switch (self.*) {
            inline else => |stmt| stmt.deinit(),
        }
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            inline else => |stmt| try writer.print("{}", .{stmt}),
        }
    }
};

pub const Block = struct {
    statements: std.ArrayList(Stmt),

    pub fn init(ast: *const Ast) Block {
        return .{
            .statements = .init(ast.alloc),
        };
    }

    pub fn deinit(self: *Block) void {
        self.statements.deinit();
    }

    pub fn add_stmt(self: *Block, stmt: Stmt) void {
        // TODO: Deal with this error more properly
        self.statements.append(stmt) catch unreachable;
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Block:\n", .{});
        for (self.statements.items) |stmt| {
            try pprinter.print(writer, .{ .stmt = stmt }, 1);
        }
    }
};

pub const Return = struct {
    expr: ?Expr = null,

    pub fn init(expr: Expr) Return {
        return .{
            .expr = expr,
        };
    }

    pub fn deinit(_: *Block) void {}

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Return:\n", .{});
        if (self.expr) |expr| {
            try pprinter.print(writer, .{ .expr = expr }, 1);
        }
    }
};

pub const Expr = union(enum) {
    func_call: FuncCall,
    number: Number,

    pub fn deinit(self: *Stmt) void {
        switch (self.*) {
            .number => |_| {},
            inline else => |expr| expr.deinit(),
        }
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            inline else => |expr| try writer.print("{}", .{expr}),
        }
    }
};

pub const FuncCall = struct {
    name: []const u8,

    pub fn init(name: []const u8) FuncCall {
        return .{
            .name = name,
        };
    }

    pub fn deinit(_: *FuncCall) void {}

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("FuncCall:\n", .{});
        try pprinter.indent(writer, 1);
        try writer.print("{s}\n", .{self.name});
    }
};

pub const Number = struct {
    value: u64,

    pub fn init(value: u64) Number {
        return .{
            .value = value,
        };
    }

    pub fn deinit(_: *Number) void {}

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Number:\n", .{});
        try pprinter.indent(writer, 1);
        try writer.print("{d}\n", .{self.value});
    }
};

// Quick aside:
//
// I have honestly never really used Zig's builtin testing functionality before,
// but I like it. It is a lot easier than having to comment out the main function
// and test our code there. I am not a fan of TDD (Test Driven Developement),
// but this is a good method of testing after we implement the features.
//
// Aside over.

const testing = std.testing;
test "Ast - Simple test" {
    const prog = Program.init(testing.allocator); // Jut a dummy progran node

    var ast: Ast = .init(prog);
    defer ast.deinit();
}

test "Ast - Type casting up to AstNode" {
    // Number
    const num: Number = .init(27);

    std.debug.print("\n{}", .{ num });

    // Number -> Expr
    const num_expr: Expr = .{ .number = num };

    std.debug.print("{}", .{ num_expr });

    // Number -> Expr -> AstNode
    const num_ast_node: AstNode = .{ .expr = num_expr };

    std.debug.print("{}", .{ num_ast_node });
}

test "Ast - Type casting AstNode" {
    const num_ast_node: AstNode = .{ .expr = .{ .number = .init(42) }};

    std.debug.print("\n{}", .{ num_ast_node });
}

test "Ast - Forming an AST" {
    const func = FuncDecl.init("foo", .{ .ret = .init(.{ .number = .init(42) }) });

    var prog = Program.init(testing.allocator);
    prog.add_decl(.{ .func_decl = func });

    std.debug.print("\n{}", .{prog});

    prog.deinit();
}
