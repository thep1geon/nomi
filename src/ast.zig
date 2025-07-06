const std = @import("std");
const Allocator = std.mem.Allocator;

const pprinter = struct {
    var ilevel: usize = 0;

    pub fn indent(indent_level: usize) void {
        for (0..indent_level) |_| {
            std.debug.print("  ", .{});
        }
    }

    pub fn print(ast: Ast, indent_level: usize) void {
        const level = ilevel;
        defer ilevel = level;
        ilevel = indent_level;
        indent(indent_level);
        ast.pprint();
    }
};

var alloc: Allocator = undefined;
pub fn init(allocator: Allocator) void {
    alloc = allocator;
}

pub const Ast = union(enum) {
    program: *Program,
    func_decl: *FuncDecl,
    block: *Block,
    ret: *Return,
    func_call: *FuncCall,
    integer: *Integer,

    pub fn pprint(self: *const Ast) void {
        switch (self.*) {
            inline else => |case| case.pprint(),
        }
    }

    pub fn deinit(self: *const Ast) void {
        switch (self.*) {
            inline else => |case| case.deinit(),
        }
    }

    pub fn emit(self: *const Ast, writer: anytype) anyerror!void {
        switch (self.*) {
            inline else => |case| try case.emit(writer),
        }
    }
};

pub const Program = struct {
    func: Ast,

    pub fn init(func: Ast) *Program {
        var prog = alloc.create(Program) catch @panic("Out of memory :/");
        prog.func = func;

        return prog;
    }

    pub fn deinit(self: *Program) void {
        self.func.deinit();
        alloc.destroy(self);
    }

    pub fn ast(self: *Program) Ast {
        return .{ .program = self };
    }

    pub fn pprint(self: *Program) void {
        std.debug.print("Progam:\n", .{});
        pprinter.print(self.func, pprinter.ilevel + 1);
    }

    pub fn emit(self: *Program, writer: anytype) anyerror!void {
        _ = try writer.write("format ELF64\n");
        _ = try writer.write("section '.text' executable\n");
        _ = try writer.write("include 'lib/std.asm'\n\n");
        try self.func.emit(writer);
    }
};

pub const FuncDecl = struct {
    name: []const u8,
    stmt: Ast,

    pub fn init(name: []const u8, stmt: Ast) *FuncDecl {
        var func_decl = alloc.create(FuncDecl) catch @panic("Out of memory :/");
        func_decl.name = name;
        func_decl.stmt = stmt;

        return func_decl;
    }

    pub fn deinit(self: *FuncDecl) void {
        self.stmt.deinit();
        alloc.destroy(self);
    }

    pub fn ast(self: *FuncDecl) Ast {
        return .{ .func_decl = self };
    }

    pub fn pprint(self: *FuncDecl) void {
        std.debug.print("FuncDecl:\n", .{});
        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("Name:\n", .{});
        pprinter.indent(pprinter.ilevel + 2);
        std.debug.print("{s}\n", .{self.name});
        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("Body:\n", .{});
        pprinter.print(self.stmt, pprinter.ilevel + 2);
    }

    pub fn emit(self: *FuncDecl, writer: anytype) anyerror!void {
        try writer.print("public {s}\n", .{self.name});
        try writer.print("{s}:\n", .{self.name});
        _ = try writer.write("    push       rbp\n");
        _ = try writer.write("    mov        rbp, rsp\n");
        try self.stmt.emit(writer);
    }
};

pub const Block = struct {
    stmts: std.ArrayList(Ast),

    pub fn init() *Block {
        var block = alloc.create(Block) catch @panic("Out of memory :/");
        block.stmts = std.ArrayList(Ast).init(alloc);

        return block;
    }

    pub fn deinit(self: *Block) void {
        for (self.stmts.items) |stmt| {
            stmt.deinit();
        }
        self.stmts.deinit();
        alloc.destroy(self);
    }

    pub fn add_stmt(self: *Block, stmt: Ast) void {
        self.stmts.append(stmt) catch @panic("🤷");
    }

    pub fn ast(self: *Block) Ast {
        return .{ .block = self };
    }

    pub fn pprint(self: *Block) void {
        std.debug.print("Block:\n", .{});
        for (self.stmts.items) |stmt| {
            pprinter.print(stmt, pprinter.ilevel + 1);
        }
    }

    pub fn emit(self: *Block, writer: anytype) anyerror!void {
        for (self.stmts.items) |stmt| {
            try stmt.emit(writer);
        }
    }
};

pub const Return = struct {
    expr: Ast,

    pub fn init(expr: Ast) *Return {
        var ret = alloc.create(Return) catch @panic("Out of memory :/");
        ret.expr = expr;

        return ret;
    }

    pub fn deinit(self: *Return) void {
        self.expr.deinit();
        alloc.destroy(self);
    }

    pub fn ast(self: *Return) Ast {
        return .{ .ret = self };
    }

    pub fn pprint(self: *Return) void {
        std.debug.print("Return:\n", .{});

        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("Expr:\n", .{});

        pprinter.print(self.expr, pprinter.ilevel + 2);
    }

    pub fn emit(self: Return, writer: anytype) anyerror!void {
        switch (self.expr) {
            .integer => |int| {
                try writer.print("    mov        rax, {d}\n", .{int.num});
            },
            .func_call => |_| {
                try self.expr.emit(writer);
            },
            else => unreachable,
        }
        _ = try writer.write("    pop        rbp\n");
        _ = try writer.write("    ret\n");
    }
};

pub const FuncCall = struct {
    name: []const u8,
    arg: Ast,

    pub fn init(name: []const u8, arg: Ast) *FuncCall {
        var funcall = alloc.create(FuncCall) catch @panic("Out of memory :/");
        funcall.name = name;
        funcall.arg = arg;

        return funcall;
    }

    pub fn deinit(self: *FuncCall) void {
        self.arg.deinit();
        alloc.destroy(self);
    }

    pub fn ast(self: *FuncCall) Ast {
        return .{ .func_call = self };
    }

    pub fn pprint(self: *FuncCall) void {
        std.debug.print("FuncCall:\n", .{});

        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("Name:\n", .{});

        pprinter.indent(pprinter.ilevel + 2);
        std.debug.print("{s}\n", .{self.name});

        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("Arg:\n", .{});

        pprinter.print(self.arg, pprinter.ilevel + 2);
    }

    pub fn emit(self: FuncCall, writer: anytype) anyerror!void {
        switch (self.arg) {
            .integer => |int| {
                try writer.print("    mov        rdi, {d}\n", .{int.num});
            },
            .func_call => |_| {
                try self.arg.emit(writer);
                _ = try writer.write("    mov        rdi, rax\n");
            },
            else => unreachable,
        }
        try writer.print("    call       {s}\n", .{self.name});
    }
};

pub const Integer = struct {
    num: u64,

    pub fn init(num: u64) *Integer {
        var integer = alloc.create(Integer) catch @panic("Out of memory :/");
        integer.num = num;

        return integer;
    }

    pub fn deinit(self: *Integer) void {
        alloc.destroy(self);
    }

    pub fn ast(self: *Integer) Ast {
        return .{ .integer = self };
    }

    pub fn pprint(self: *Integer) void {
        std.debug.print("Integer:\n", .{});
        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("{d}\n", .{self.num});
    }

    pub fn emit(self: *Integer, writer: anytype) anyerror!void {
        _ = .{ self, writer };
        unreachable;
    }
};
