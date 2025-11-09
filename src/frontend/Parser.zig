const std = @import("std");
const Allocator = std.mem.Allocator;

const ast = @import("ast.zig");

const lex = @import("lex.zig");
const Token = lex.Token;
const TokenKind = Token.Kind;
const Lexer = lex.Lexer;

pub const Error = error{
    UnexpectedToken,
    ExpectedStatement,
};

const Self = @This();

lexer: *Lexer,
allocator: Allocator,

pub fn init(lexer: *Lexer, alloc: Allocator) Self {
    return .{
        .lexer = lexer,
        .allocator = alloc,
    };
}

pub fn parse(self: *Self) Error!ast.Ast {
    const prog = try self.parse_program();
    return ast.Ast.init(prog);
}

fn parse_program(self: *Self) Error!ast.Program {
    var prog = ast.Program.init(self.allocator);
    prog.add_decl(try self.parse_decl());

    return prog;
}

fn parse_decl(self: *Self) Error!ast.Decl {
    return .{ .func_decl = try self.parse_func_decl() };
}

fn parse_func_decl(self: *Self) Error!ast.FuncDecl {
    _ = try self.expect_next(.kw_func);
    
    const tok = try self.expect_next(.ident);

    _ = try self.expect_next(.lparen);
    _ = try self.expect_next(.rparen);

    var toks = [_]TokenKind{.kw_void, .kw_i32};
    _ = try self.expect_next_of(toks[0..]);

    const stmt = try self.parse_stmt();

    return ast.FuncDecl.init(tok.str, stmt);
}

fn parse_stmt(self: *Self) Error!ast.Stmt {
    const tok = self.lexer.peek() catch |err| {
        std.debug.print("{f}: Expected statement, ", .{self.lexer.err_loc});
        return handle_lexing_error(err);
    };

    switch (tok.kind) {
        .lcurly => return .{ .block = try self.parse_block() },
        .kw_return => return .{ .ret = try self.parse_return() },
        else => {
            const expr = try self.parse_expr();

            _ = try self.expect_next(.semicolon);

            return .{ .expr = expr };
        },
    }
}

fn parse_block(self: *Self) Error!ast.Block {
    var block = ast.Block.init(self.allocator);
    _ = self.lexer.next() catch unreachable; // Consume the curly brace as not to overflow the stack

    while (true) {
        const tok = self.lexer.peek() catch |err| {
            std.debug.print("{f}: Expected closing brace, ", .{self.lexer.err_loc});
            return handle_lexing_error(err);
        };

        if (tok.kind == .rcurly) break; // We found the closing curly brace for the block

        const stmt = try self.parse_stmt();
        block.add_stmt(stmt);
    }

    return block;
}

fn parse_return(self: *Self) Error!ast.Return {
    _ = try self.expect_next(.kw_return);

    const expr = try self.parse_expr();

    _ = try self.expect_next(.semicolon);

    return ast.Return.init(expr);
}

fn parse_expr(self: *Self) Error!ast.Expr {
    const tok = self.lexer.peek() catch |err| {
        std.debug.print("{f}: Expected expression ", .{self.lexer.err_loc});
        return handle_lexing_error(err);
    };

    if (tok.kind == .ident) {
        return .{ .func_call = try self.parse_func_call() };
    }

    return .{ .number = try self.parse_number() };
}

fn parse_func_call(self: *Self) Error!ast.FuncCall {
    const ident_tok = self.lexer.next() catch unreachable;

    _ = try self.expect_next(.lparen);
    _ = try self.expect_next(.rparen);

    return ast.FuncCall.init(ident_tok.str);
}

fn parse_number(self: *Self) Error!ast.Number {
    const tok = try self.expect_next(.integer);

    const num = std.fmt.parseInt(u64, tok.str, 10) catch unreachable;

    return ast.Number.init(num);
}

fn expect_next(self: *Self, kind: TokenKind) Error!Token {
    const tok = self.lexer.next() catch |err| {
        std.debug.print("{f}: Expected {f} ", .{self.lexer.err_loc, kind});
        return handle_lexing_error(err);
    };

    if (tok.kind != kind) {
        std.debug.print("{f}: Expected {f} but found {f} instead.\n", .{tok.loc, kind, tok.kind});
        return Error.UnexpectedToken;
    }

    return tok;
}

fn expect_next_of(self: *Self, kinds: []TokenKind) Error!Token {
    const tok = self.lexer.next() catch |err| {
        std.debug.print("{f}: Expected ", .{self.lexer.err_loc});
        for (kinds) |kind| {
            std.debug.print("{f}, ", .{kind});
        }
        return handle_lexing_error(err);
    };

    for (kinds) |kind| {
        if (kind == tok.kind) {
            return tok;
        }
    }

    std.debug.print("{f}: Expected ", .{tok.loc});
    for (kinds) |kind| {
        std.debug.print("{f}, ", .{kind});
    }
    std.debug.print("but found {f} instead\n", .{tok.kind});
    return Error.UnexpectedToken;
}

fn handle_lexing_error(err: Lexer.Error) Error {
    switch (err) {
        Lexer.Error.EndOfFile => std.debug.print("found end of file instead.\n", .{}),
        Lexer.Error.UnknownCharacter => std.debug.print("found unknown character instead.\n", .{}),
    }
    return Error.UnexpectedToken;
}
