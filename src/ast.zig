const std = @import("std");

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
        };

        return .{
            .ptr = ast_ptr,
            .pprint_fn = gen.pprint,
        };
    }

    pub fn pprint(self: Ast) void {
        self.pprint_fn(self.ptr);
    }
};

pub const Program = struct {
    func: FuncDecl,

    pub fn init(func: FuncDecl) Program {
        return .{
            .func = func,
        };
    }

    pub fn ast(self: *Program) Ast {
        return Ast.init(self);
    }

    pub fn pprint(self: *Program) void {
        std.debug.print("Progam:\n", .{});
        pprinter.print(self.func.ast(), pprinter.ilevel + 1);
    } };

pub const FuncDecl = struct {
    name: []const u8,
    stmt: Ast,

    pub fn init(name: []const u8, stmt: Ast) FuncDecl {
        return .{
            .name = name,
            .stmt = stmt,
        };
    }

    pub fn ast(self: *FuncDecl) Ast {
        return Ast.init(self);
    }

    pub fn pprint(self: *FuncDecl) void {
        std.debug.print("FuncDecl:\n", .{});
        pprinter.print(self.stmt, pprinter.ilevel + 1);
    }
};

pub const Block = struct {
    stmt: Ast,

    pub fn init(stmt: Ast) Block {
        return .{
            .stmt = stmt,
        };
    }

    pub fn ast(self: *Block) Ast {
        return Ast.init(self);
    }

    pub fn pprint(self: *Block) void {
        std.debug.print("Block:\n", .{});
        pprinter.print(self.stmt, pprinter.ilevel + 1);
    }
};

pub const Funcall = struct {
    name: []const u8,
    arg: Ast,

    pub fn init(name: []const u8, arg: Ast) Funcall {
        return .{
            .name = name,
            .arg = arg,
        };
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
};

pub const Integer = struct {
    num: u64,

    pub fn init(num: u64) Integer {
        return .{
            .num = num,
        };
    }

    pub fn ast(self: *Integer) Ast {
        return Ast.init(self);
    }

    pub fn pprint(self: *Integer) void {
        std.debug.print("Integer:\n", .{});
        pprinter.indent(pprinter.ilevel + 1);
        std.debug.print("{d}\n", .{self.num});
    }
};
