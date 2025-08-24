const std = @import("std");
const Allocator = std.mem.Allocator;

//  FuncDecl main:
//      Return 42

pub const List = struct {
    list: std.ArrayList(Stmt),

    pub fn init(alloc: std.mem.Allocator) List {
        return .{
            .list = .init(alloc),
        };
    }

    pub fn deinit(list: *List) void {
        list.list.deinit();
    }

    pub fn format(
        self: *const List,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        try writer.print("List:\n", .{});

        for (self.list.items) |stmt| {
            switch (stmt) {
                .func_decl => try writer.print("{}\n", .{ stmt }),
                else => try writer.print("  {}\n", .{ stmt }),
            }
        }
    }
};

pub const Stmt = union(enum) {
    func_decl: FuncDecl,
    ret: Return,

    pub fn format(
        self: *const Stmt,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        switch (self.*) {
            inline else => |stmt| try writer.print("{}", .{ stmt }),
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
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
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
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        try writer.print("Return ({})", .{ self.expr });
    }
};

pub const Expr = union(enum) {
    integer: u64,

    pub fn format(
        self: *const Expr,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        _ = .{ fmt, options };
        switch (self.*) {
            .integer => |data| try writer.print("{d}", .{ data }),
            // inline else => |expr| try writer.print("{}", .{ expr }),
        }
    }
};
