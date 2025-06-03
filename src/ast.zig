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

pub var alloc: Allocator = undefined;

pub const Ast = struct {
    pub const Kind = enum {
        program,
        func_decl,
        block,
        funcall,
        integer,
    };

    kind: Kind,
    ptr: *anyopaque,
    pprint_fn: *const fn (ptr: *anyopaque) void,
    deinit_fn: *const fn (ptr: *anyopaque) void,
    emit_fn: *const fn (ptr: *anyopaque) void,

    pub fn init(ast_ptr: anytype, kind: Kind) Ast {
        const T = @TypeOf(ast_ptr);
        std.debug.assert(@typeInfo(T) == .pointer);
        std.debug.assert(@typeInfo(T).pointer.size == .one);
        std.debug.assert(@typeInfo(@typeInfo(T).pointer.child) == .@"struct");

        const gen = struct {
            inline fn get_self(ptr: *anyopaque) T {
                return @ptrCast(@alignCast(ptr));
            }

            pub fn pprint(ptr: *anyopaque) void {
                get_self(ptr).pprint();
            }

            pub fn deinit(ptr: *anyopaque) void {
                get_self(ptr).deinit();
            }

            pub fn emit(ptr: *anyopaque) void {
                get_self(ptr).emit();
            }
        };

        return .{
            .kind = kind,
            .ptr = ast_ptr,
            .pprint_fn = gen.pprint,
            .deinit_fn = gen.deinit,
            .emit_fn = gen.emit,
        };
    }

    pub fn pprint(self: *const Ast) void {
        self.pprint_fn(self.ptr);
    }

    pub fn deinit(self: *const Ast) void {
        self.deinit_fn(self.ptr);
    }

    pub fn emit(self: *const Ast) void {
        self.emit_fn(self.ptr);
    }

    pub fn as(self: *const Ast, T: anytype) T {
        std.debug.assert(@typeInfo(T) == .pointer);
        std.debug.assert(@typeInfo(T).pointer.size == .one);
        std.debug.assert(@typeInfo(@typeInfo(T).pointer.child) == .@"struct");
        return @ptrCast(@alignCast(self.ptr));
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
        return Ast.init(self, .program);
    }

    pub fn pprint(self: *Program) void {
        std.debug.print("Progam:\n", .{});
        pprinter.print(self.func, pprinter.ilevel + 1);
    } 

    pub fn emit(self: *Program) void {
        std.debug.print("    .text\n", .{});
        std.debug.print("    .globl main\n", .{});
        self.func.emit();
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
        return Ast.init(self, .func_decl);
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

    pub fn emit(self: *FuncDecl) void {
        std.debug.print("{s}:\n", .{self.name});
        std.debug.print("    pushq      %rbp\n", .{});
        std.debug.print("    movq       %rsp, %rbp\n", .{});
        self.stmt.emit();
        std.debug.print("    popq       %rbp\n", .{});
        std.debug.print("    ret\n", .{});
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
        return Ast.init(self, .block);
    }

    pub fn pprint(self: *Block) void {
        std.debug.print("Block:\n", .{});
        for (self.stmts.items) |stmt| {
            pprinter.print(stmt, pprinter.ilevel + 1);
        }
    }

    pub fn emit(self: *Block) void {
        for (self.stmts.items) |stmt| {
            stmt.emit();
        }
    }
};

pub const Funcall = struct {
    name: []const u8,
    arg: Ast,

    pub fn init(name: []const u8, arg: Ast) *Funcall {
        var funcall = alloc.create(Funcall) catch @panic("Out of memory :/");
        funcall.name = name;
        funcall.arg = arg;

        return funcall;
    }

    pub fn deinit(self: *Funcall) void {
        self.arg.deinit();
        alloc.destroy(self);
    }

    pub fn ast(self: *Funcall) Ast {
        return Ast.init(self, .funcall);
    }

    pub fn pprint(self: *Funcall) void {
        std.debug.print("Funcall:\n", .{});

        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("Name:\n", .{});

        pprinter.indent(pprinter.ilevel + 2);
        std.debug.print("{s}\n", .{self.name});

        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("Arg:\n", .{});

        pprinter.print(self.arg, pprinter.ilevel + 2);
    }

    pub fn emit(self: Funcall) void {
        switch (self.arg.kind) {
            .integer => {
                const int = self.arg.as(*Integer);
                std.debug.print("    movq       ${d}, %rdi\n", .{int.num});
            },
            .funcall => {
                self.arg.emit();
                std.debug.print("    movq       %rax, %rdi\n", .{});
            },
            else => unreachable,
        }
        std.debug.print("    call       {s}\n", .{self.name});
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
        return Ast.init(self, .integer);
    }

    pub fn pprint(self: *Integer) void {
        std.debug.print("Integer:\n", .{});
        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("{d}\n", .{self.num});
    }

    pub fn emit(self: *Integer) void {
        std.debug.print("    pushq      ${d}\n", .{self.num});
    }
};
