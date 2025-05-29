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

pub const Ast = struct {
    ptr: *anyopaque,
    pprint_fn: *const fn (ptr: *anyopaque) void,
    deinit_fn: *const fn (ptr: *anyopaque, allocator: Allocator) void,
    emit_fn: *const fn (ptr: *anyopaque) void,

    pub fn init(ast_ptr: anytype) Ast {
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

            pub fn deinit(ptr: *anyopaque, allocator: Allocator) void {
                get_self(ptr).deinit(allocator);
            }

            pub fn emit(ptr: *anyopaque) void {
                get_self(ptr).emit();
            }
        };

        return .{
            .ptr = ast_ptr,
            .pprint_fn = gen.pprint,
            .deinit_fn = gen.deinit,
            .emit_fn = gen.emit,
        };
    }

    pub fn pprint(self: *const Ast) void {
        self.pprint_fn(self.ptr);
    }

    pub fn deinit(self: *const Ast, allocator: Allocator) void {
        self.deinit_fn(self.ptr, allocator);
    }

    pub fn emit(self: *const Ast) void {
        self.emit_fn(self.ptr);
    }
};

pub const Program = struct {
    func: Ast,

    pub fn init(allocator: Allocator, func: Ast) *Program {
        var prog = allocator.create(Program) catch @panic("Out of memory :/");
        prog.func = func;

        return prog;
    }

    pub fn deinit(self: *Program, allocator: Allocator) void {
        self.func.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn ast(self: *Program) Ast {
        return Ast.init(self);
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

    pub fn init(allocator: Allocator, name: []const u8, stmt: Ast) *FuncDecl {
        var func_decl = allocator.create(FuncDecl) catch @panic("Out of memory :/");
        func_decl.name = name;
        func_decl.stmt = stmt;

        return func_decl;
    }

    pub fn deinit(self: *FuncDecl, allocator: Allocator) void {
        self.stmt.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn ast(self: *FuncDecl) Ast {
        return Ast.init(self);
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
    stmt: Ast,

    pub fn init(allocator: Allocator, stmt: Ast) *Block {
        var block = allocator.create(Block) catch @panic("Out of memory :/");
        block.stmt = stmt;

        return block;
    }

    pub fn deinit(self: *Block, allocator: Allocator) void {
        self.stmt.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn ast(self: *Block) Ast {
        return Ast.init(self);
    }

    pub fn pprint(self: *Block) void {
        std.debug.print("Block:\n", .{});
        pprinter.print(self.stmt, pprinter.ilevel + 1);
    }

    pub fn emit(self: *Block) void {
        self.stmt.emit();
    }
};

pub const Funcall = struct {
    name: []const u8,
    arg: Ast,

    pub fn init(allocator: Allocator, name: []const u8, arg: Ast) *Funcall {
        var funcall = allocator.create(Funcall) catch @panic("Out of memory :/");
        funcall.name = name;
        funcall.arg = arg;

        return funcall;
    }

    pub fn deinit(self: *Funcall, allocator: Allocator) void {
        self.arg.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn ast(self: *Funcall) Ast {
        return Ast.init(self);
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
        self.arg.emit();
        std.debug.print("    popq       %rdi\n", .{});
        std.debug.print("    call       {s}\n", .{self.name});
    }
};

pub const Integer = struct {
    num: u64,

    pub fn init(allocator: Allocator, num: u64) *Integer {
        var integer = allocator.create(Integer) catch @panic("Out of memory :/");
        integer.num = num;

        return integer;
    }

    pub fn deinit(self: *Integer, allocator: Allocator) void {
        allocator.destroy(self);
    }

    pub fn ast(self: *Integer) Ast {
        return Ast.init(self);
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
