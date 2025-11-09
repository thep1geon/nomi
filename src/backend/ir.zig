const std = @import("std");
const Allocator = std.mem.Allocator;

//  FuncDecl main:
//      Return 42

pub const List = struct {
    list: std.ArrayList(Stmt) = .{},
    allocator: Allocator,

    pub fn init(alloc: std.mem.Allocator) List {
        return .{
            .allocator = alloc,
        };
    }

    pub fn deinit(list: *List) void {
        list.list.deinit(list.allocator);
    }

    pub fn format(
        self: *const List,
        writer: *std.io.Writer,
    ) anyerror!void {
        try writer.print("List:\n", .{});

        for (self.list.items) |stmt| {
            switch (stmt) {
                .func_decl => try writer.print("{}\n", .{ stmt }),
                else => try writer.print("  {f}\n", .{ stmt }),
            }
        }
    }
};

pub const Stmt = union(enum) {
    func_decl: FuncDecl,
    ret: Return,

    pub fn format(
        self: *const Stmt,
        writer: *std.io.Writer,
    ) anyerror!void {
        switch (self.*) {
            inline else => |stmt| try writer.print("{f}", .{ stmt }),
        }
    }
};

pub const FuncDecl = struct {
    name: []const u8,

    pub fn init(allocator: Allocator, name: []const u8) FuncDecl {
        return .{ .name = name, .scope = .init(allocator) };
    }

    pub fn format(
        self: *const FuncDecl,
        writer: *std.io.Writer,
    ) anyerror!void {
        try writer.print("FuncDecl ({s}):", .{ self.name });
    }

};

pub const Return = struct {
    expr: Expr,

    pub fn init(expr: Expr) Return {
        return .{ .expr = expr };
    }

    pub fn format(
        self: *const Return,
        writer: *std.io.Writer,
    ) anyerror!void {
        try writer.print("Return ({f})", .{ self.expr });
    }
};

pub const Expr = union(enum) {
    integer: u64,

    pub fn format(
        self: *const Expr,
        writer: *std.io.Writer,
    ) anyerror!void {
        switch (self.*) {
            .integer => |data| try writer.print("{d}", .{ data }),
            // inline else => |expr| try writer.print("{}", .{ expr }),
        }
    }
};
