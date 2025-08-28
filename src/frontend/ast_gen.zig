const std = @import("std");
const Allocator = std.mem.Allocator;

const ir = @import("../backend.zig").ir;

const ast = @import("ast.zig");
const Ast = ast.Ast;

// Function declaration - "func main() i32 { return 42; }"
//     - Function signature - "main() i32"
//         - Name of the function - "main"
//         - Arguments it takes - "()" [Empty for now]
//         - Return type - "i32"
//
//     - Function Body - "{ return 42; }"
//         - A statement - "{ ... }"
//             - Having a list of statements
//                 - "return 42"
//
// As IR this would be:
//
// FuncDecl main:
//     Return 42

pub fn gen(alloc: Allocator, ast_: *Ast) !ir.List {
    const prog = ast_.program;
    var list = ir.List.init(alloc);

    for (prog.declarations.items) |*decl| {
        switch (decl.*) {
            .func_decl => |*func| try gen_func_decl(&list, func),
        }
    }

    return list;
}

pub fn gen_func_decl(ir_list: *ir.List, func_decl: *const ast.FuncDecl) !void {
    try ir_list.list.append(.{.func_decl = .{ .name = func_decl.name }});

    // Generate the statment of the func_decl
    try gen_stmt(ir_list, &func_decl.stmt);
}

pub fn gen_stmt(ir_list: *ir.List, stmt: *const ast.Stmt) !void {
    switch (stmt.*) {
        .block => |*block| try gen_block(ir_list, block),
        .ret => |*ret| try gen_ret(ir_list, ret),
        .expr => |_| @panic("hrm"),
    }
}

pub fn gen_block(ir_list: *ir.List, block: *const ast.Block) !void {
    for (block.statements.items) |stmt| {
        switch (stmt) {
            .block => |*block_| try gen_block(ir_list, block_),
            .ret => |*ret| try gen_ret(ir_list, ret),
            .expr => |_| @panic("hrm"),
        }
    }
}

pub fn gen_ret(ir_list: *ir.List, ret: *const ast.Return) !void {
    const ret_expr: ir.Expr =  if (ret.expr) |expr| 
        ast_expr_to_ir_expr(expr)
        else .{ .integer = 0 };
    try ir_list.list.append(.{.ret = .init(ret_expr)});

    return;
}

fn ast_expr_to_ir_expr(expr: ast.Expr) ir.Expr {
    return switch (expr) {
        // TODO: Implement this feature
        .func_call => |_| @panic("not implemented yet"),
        .number => |n| ir.Expr{ .integer = n.value },
    };
}
