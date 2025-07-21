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
    return self.parse_program();
}

fn parse_program(self: *Self) Error!ast.Ast {
    return ast.Program.init(try self.parse_decl(), self.allocator).ast();
}

fn parse_decl(self: *Self) Error!ast.Ast {
    return self.parse_func_decl();
}

fn parse_func_decl(self: *Self) Error!ast.Ast {
    _ = try self.expect_next(.kw_func);
    
    const tok = try self.expect_next(.ident);

    _ = try self.expect_next(.lparen);
    _ = try self.expect_next(.rparen);

    var toks = [_]TokenKind{.kw_void, .kw_i32};
    _ = try self.expect_next_of(toks[0..]);

    const stmt = try self.parse_stmt();

    return ast.FuncDecl.init(tok.str, stmt, self.allocator).ast();
}

fn parse_stmt(self: *Self) Error!ast.Ast {
    const tok = self.lexer.peek() catch |err| {
        std.debug.print("{}: Expected statement, ", .{self.lexer.err_loc});
        return handle_lexing_error(err);
    };

    switch (tok.kind) {
        .lcurly => return self.parse_block(),
        .kw_return => return self.parse_return(),
        else => {
            const expr = try self.parse_expr();

            _ = try self.expect_next(.semicolon);

            return expr;
        },
    }
}

fn parse_block(self: *Self) Error!ast.Ast {
    var block = ast.Block.init(self.allocator);
    _ = self.lexer.next() catch unreachable; // Consume the curly brace as not to overflow the stack

    while (true) {
        const tok = self.lexer.peek() catch |err| {
            std.debug.print("{}: Expected closing brace, ", .{self.lexer.err_loc});
            return handle_lexing_error(err);
        };

        if (tok.kind == .rcurly) break; // We found the closing curly brace for the block

        const stmt = try self.parse_stmt();
        block.add_stmt(stmt);
    }

    return block.ast();
}

fn parse_return(self: *Self) Error!ast.Ast {
    _ = try self.expect_next(.kw_return);

    const expr = try self.parse_expr();

    _ = try self.expect_next(.semicolon);

    return ast.Return.init(expr, self.allocator).ast();
}

fn parse_expr(self: *Self) Error!ast.Ast {
    const tok = self.lexer.peek() catch |err| {
        std.debug.print("{}: Expected expression ", .{self.lexer.err_loc});
        return handle_lexing_error(err);
    };

    if (tok.kind == .ident) {
        return self.parse_func_call();
    }

    return self.parse_number();
}

fn parse_func_call(self: *Self) Error!ast.Ast {
    const ident_tok = self.lexer.next() catch unreachable;

    _ = try self.expect_next(.lparen);
    const arg = try self.parse_expr();
    _ = try self.expect_next(.rparen);

    return ast.FuncCall.init(ident_tok.str, arg, self.allocator).ast();
}

fn parse_number(self: *Self) Error!ast.Ast {
    const tok = try self.expect_next(.integer);

    const num = std.fmt.parseInt(u64, tok.str, 10) catch unreachable;

    return ast.Integer.init(num, self.allocator).ast();
}

fn expect_next(self: *Self, kind: TokenKind) Error!Token {
    const tok = self.lexer.next() catch |err| {
        std.debug.print("{}: Expected {} ", .{self.lexer.err_loc, kind});
        return handle_lexing_error(err);
    };

    if (tok.kind != kind) {
        std.debug.print("{}: Expected {} but found {} instead.\n", .{tok.loc, kind, tok.kind});
        return Error.UnexpectedToken;
    }

    return tok;
}

fn expect_next_of(self: *Self, kinds: []TokenKind) Error!Token {
    const tok = self.lexer.next() catch |err| {
        std.debug.print("{}: Expected ", .{self.lexer.err_loc});
        for (kinds) |kind| {
            std.debug.print("{}, ", .{kind});
        }
        return handle_lexing_error(err);
    };

    for (kinds) |kind| {
        if (kind == tok.kind) {
            return tok;
        }
    }

    std.debug.print("{}: Expected ", .{tok.loc});
    for (kinds) |kind| {
        std.debug.print("{}, ", .{kind});
    }
    std.debug.print("but found {} instead\n", .{tok.kind});
    return Error.UnexpectedToken;
}

fn handle_lexing_error(err: Lexer.Error) Error {
    switch (err) {
        Lexer.Error.EndOfFile => std.debug.print("found end of file instead.\n", .{}),
        Lexer.Error.UnknownCharacter => std.debug.print("found unknown character instead.\n", .{}),
    }
    return Error.UnexpectedToken;
}
