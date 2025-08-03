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

// It might seem a little backwards, but we actually want to build up the actual
// AST (starting at the Program) before passing it into the Ast instance. The point
// of the Ast type and instance is to keep track of everything after the AST has
// been built. A single Ast type also lets us do semantic analysis on it, type checking,
// easier conversion to IR, etc.
pub const Ast = struct {
    program: ?Program = null,
    alloc: Allocator,

    pub fn init(allocator: Allocator) Ast {
        return .{
            .alloc = allocator,
        };
    }

    pub fn deinit(self: *Ast) void {
        if (self.program) |*prog| {
            prog.deinit(self);
        }
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        if (self.program) |*prog| {
            try writer.print("{}", .{ prog });
        }
    }

};

const pretty_printer = struct {};

// The actual node types that make up the AST
//
// When dealing with initialization and deinitialization, we pass around a const
// pointer to the AST instance. This allows us to let the AST instance keep track
// of everything and keeps everything owned by the AST.
//
// This keeps everything central and clean.

pub const Program = struct {
    declarations: std.ArrayList(Decl),

    pub fn init(ast: *const Ast) Program {
        return .{
            .declarations = .init(ast.alloc),
        };
    }

    pub fn deinit(self: *Program, _: *const Ast) void {
        self.declarations.deinit();
    }

    pub fn add_decl(self: *Program, decl: Decl) void {
        // HACK: Deal with this error more properly
        self.declarations.append(decl) catch @panic("TODO: Deal with this error properly");
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Program:\n", .{});
        for (self.declarations.items) |decl| {
            // Indent Once
            try writer.print("{}\n", .{ decl });
        }
    }
};

pub const Decl = union(enum) {
    func_decl: FuncDecl,

    pub fn deinit(self: *Decl, ast: *const Ast) void {
        switch (self.*) {
            inline else => |decl| decl.deinit(ast),
        }
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            inline else => |decl| try writer.print("{}\n", .{ decl }),
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

    pub fn deinit(_: *FuncDecl, _: *const Ast) void {}

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("FuncDecl:\n", .{});
        // Indent once
        try writer.print("Name:\n", .{});
        // Indent twice
        try writer.print("{s}\n", .{ self.name });
        // Indent once
        try writer.print("Body:\n", .{});
        // Indent Twice
        try writer.print("{}\n", .{ self.stmt });
    }
};

pub const Stmt = union(enum) {
    block: Block,
    ret: Return,
    expr: Expr,


    pub fn deinit(self: *Stmt, ast: *const Ast) void {
        switch (self.*) {
            inline else => |stmt| stmt.deinit(ast),
        }
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            inline else => |stmt| try writer.print("{}\n", .{ stmt }),
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

    pub fn deinit(self: *Block, _: *const Ast) void {
        self.statements.deinit();
    }

    pub fn add_stmt(self: *Block, stmt: Stmt) void {
        // HACK: Deal with this error more properly
        self.statements.append(stmt) catch @panic("TODO: Deal with this error properly");
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Block:\n", .{});
        for (self.statements.items) |stmt| {
            // Indent once
            try writer.print("{}\n", .{ stmt });
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

    pub fn deinit(_: *Block, _: *const Ast) void {}

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Return:\n", .{});
        if (self.expr) |*expr| {
            // Indent once
            try writer.print("{}\n", .{ expr });
        }
    }
};

pub const Expr = union(enum) {
    func_call: FuncCall,
    number: Number,

    pub fn deinit(self: *Stmt, ast: *const Ast) void {
        switch (self.*) {
            .number => |_| {},
            inline else => |expr| expr.deinit(ast),
        }
    }

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            .number => |num| try writer.print("{d}\n", .{ num }),
            inline else => |expr| try writer.print("{}\n", .{ expr }),
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

    pub fn deinit(_: *FuncCall, _: *const Ast) void {}

    pub fn format(
        self: *const @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("FuncCall:\n", .{});
        // Indent once
        try writer.print("{s}\n", .{ self.name });
    }
};

pub const Number = u64;


// Quick aside:
//
// I have honestly never really used Zig's builtin testing functionality before,
// but I like it. It is a lot easier than having to comment out the main function
// and test our code there. I am not a fan of TDD (Test Driven Developement),
// but this is a good method of testing after we implement the features.
//
// Aside over.

const testing = std.testing;
test "Ast - simple test" {
    var ast: Ast = .init(testing.allocator);
    defer ast.deinit();
}

test "Ast - Actual AST" {
    var ast: Ast = .init(testing.allocator);
    defer ast.deinit();

    const func = FuncDecl.init("foo", .{ .ret = .init(.{ .number = 42 }) });

    var prog = Program.init(&ast);
    prog.add_decl(.{.func_decl = func });

    ast.program = prog;

    std.debug.print("{}\n", .{ ast });
}
