const std = @import("std");
const Allocator = std.mem.Allocator;

const pprinter = struct {
    const spaces = 2;
    var ilevel: usize = 0;

    pub fn indent(writer: anytype, indent_level: usize) anyerror!void {
        for (0..indent_level) |_| {
            try writer.print(" " ** 2, .{});
        }
    }

    pub fn print(writer: anytype, ast: Ast, indent_level: usize) anyerror!void {
        const level = ilevel;
        defer ilevel = level;
        ilevel = indent_level;
        try indent(writer, indent_level);

        try writer.print("{}", .{ast});
    }
};

pub const Ast = union(enum) {
    program: *Program,
    func_decl: *FuncDecl,
    block: *Block,
    ret: *Return,
    func_call: *FuncCall,
    integer: *Integer,

    pub fn format(
        self: *const Ast,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        switch (self.*) {
            inline else => |case| try writer.print("{}", .{case}),
        }
    }

    pub fn deinit(self: *const Ast, alloc: Allocator) void {
        switch (self.*) {
            inline else => |case| case.deinit(alloc),
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

    pub fn init(func: Ast, alloc: Allocator) *Program {
        var prog = alloc.create(Program) catch @panic("Out of memory :/");
        prog.func = func;

        return prog;
    }

    fn deinit(self: *Program, alloc: Allocator) void {
        self.func.deinit(alloc);
        alloc.destroy(self);
    }

    pub fn ast(self: *Program) Ast {
        return .{ .program = self };
    }

    pub fn format(
        self: *const Program,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        try writer.print("Progam:\n", .{});
        try pprinter.print(writer, self.func, pprinter.ilevel + 1);
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

    pub fn init(name: []const u8, stmt: Ast, alloc: Allocator) *FuncDecl {
        var func_decl = alloc.create(FuncDecl) catch @panic("Out of memory :/");
        func_decl.name = name;
        func_decl.stmt = stmt;

        return func_decl;
    }

    fn deinit(self: *FuncDecl, alloc: Allocator) void {
        self.stmt.deinit(alloc);
        alloc.destroy(self);
    }

    pub fn ast(self: *FuncDecl) Ast {
        return .{ .func_decl = self };
    }

    pub fn format(
        self: *const FuncDecl,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        try writer.print("FuncDecl:\n", .{});
        try pprinter.indent(writer, pprinter.ilevel + 1);
        try writer.print("Name:\n", .{});
        try pprinter.indent(writer, pprinter.ilevel + 2);
        try writer.print("{s}\n", .{self.name});
        try pprinter.indent(writer, pprinter.ilevel + 1);
        try writer.print("Body:\n", .{});
        try pprinter.print(writer, self.stmt, pprinter.ilevel + 2);
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

    pub fn init(alloc: Allocator) *Block {
        var block = alloc.create(Block) catch @panic("Out of memory :/");
        block.stmts = std.ArrayList(Ast).init(alloc);

        return block;
    }

    fn deinit(self: *Block, alloc: Allocator) void {
        for (self.stmts.items) |stmt| {
            stmt.deinit(alloc);
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

    pub fn format(
        self: *const Block,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        try writer.print("Block:\n", .{});
        for (self.stmts.items) |stmt| {
            try pprinter.print(writer, stmt, pprinter.ilevel + 1);
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

    pub fn init(expr: Ast, alloc: Allocator) *Return {
        var ret = alloc.create(Return) catch @panic("Out of memory :/");
        ret.expr = expr;

        return ret;
    }

    fn deinit(self: *Return, alloc: Allocator) void {
        self.expr.deinit(alloc);
        alloc.destroy(self);
    }

    pub fn ast(self: *Return) Ast {
        return .{ .ret = self };
    }

    pub fn format(
        self: *const Return,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        try writer.print("Return:\n", .{});

        try pprinter.indent(writer, pprinter.ilevel + 1);
        try writer.print("Expr:\n", .{});

        try pprinter.print(writer, self.expr, pprinter.ilevel + 2);
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

    pub fn init(name: []const u8, arg: Ast, alloc: Allocator) *FuncCall {
        var funcall = alloc.create(FuncCall) catch @panic("Out of memory :/");
        funcall.name = name;
        funcall.arg = arg;

        return funcall;
    }

    fn deinit(self: *FuncCall, alloc: Allocator) void {
        self.arg.deinit(alloc);
        alloc.destroy(self);
    }

    pub fn ast(self: *FuncCall) Ast {
        return .{ .func_call = self };
    }

    pub fn format(
        self: *const FuncCall,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        try writer.print("FuncCall:\n", .{});

        try pprinter.indent(writer, pprinter.ilevel + 1);
        try writer.print("Name:\n", .{});

        try pprinter.indent(writer, pprinter.ilevel + 2);
        try writer.print("{s}\n", .{self.name});

        try pprinter.indent(writer, pprinter.ilevel + 1);
        try writer.print("Arg:\n", .{});

        try pprinter.print(writer, self.arg, pprinter.ilevel + 2);
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

    pub fn init(num: u64, alloc: Allocator) *Integer {
        var integer = alloc.create(Integer) catch @panic("Out of memory :/");
        integer.num = num;

        return integer;
    }

    fn deinit(self: *Integer, alloc: Allocator) void {
        alloc.destroy(self);
    }

    pub fn ast(self: *Integer) Ast {
        return .{ .integer = self };
    }

    pub fn format(
        self: *const Integer,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        try writer.print("Integer:\n", .{});
        try pprinter.indent(writer, pprinter.ilevel + 1);
        try writer.print("{d}\n", .{self.num});
    }

    pub fn emit(self: *Integer, writer: anytype) anyerror!void {
        _ = .{ self, writer };
        unreachable;
    }
};
