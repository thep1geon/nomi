const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const ast = @import("ast.zig");

const lex = @import("lex.zig");
const Token = lex.Token;
const Lexer = lex.Lexer;

pub const ParsingError = error{
    UnexpectedToken,
    ExpectedStatement,
};

const Parser = @This();

lexer: Lexer,
allocator: Allocator,

pub fn init(src: []const u8, arena: *ArenaAllocator) Parser {
    const alloc = arena.allocator();
    ast.init(alloc);
    return .{
        .lexer = Lexer.init(src),
        .allocator = alloc,
    };
}

pub fn parse(self: *Parser) ParsingError!ast.Ast {
    return self.parse_program();
}

fn parse_program(self: *Parser) ParsingError!ast.Ast {
    return ast.Program.init(try self.parse_decl()).ast();
}

fn parse_decl(self: *Parser) ParsingError!ast.Ast {
    return self.parse_func_decl();
}

fn parse_func_decl(self: *Parser) ParsingError!ast.Ast {
    _ = try self.expect_next(.kw_func);
    
    const tok = try self.expect_next(.ident);

    _ = try self.expect_next(.lparen);
    _ = try self.expect_next(.rparen);

    var possible_toks = [_]Token.TokenKind{.kw_void, .kw_i32};
    _ = try self.expect_next_of(possible_toks[0..]);

    const stmt = try self.parse_stmt();

    return ast.FuncDecl.init(tok.str, stmt).ast();
}

fn parse_stmt(self: *Parser) ParsingError!ast.Ast {
    const tok = self.lexer.peek();

    if (tok == null) {
        std.debug.print("Expected Statement, found end of file\n", .{});
        return ParsingError.ExpectedStatement;
    }

    if (tok.?.kind == .lcurly) {
        return self.parse_block();
    } else if (tok.?.kind == .kw_return) {
        return self.parse_return();
    }

    const expr = try self.parse_expr();

    _ = try self.expect_next(.semicolon);

    return expr;
}

fn parse_block(self: *Parser) ParsingError!ast.Ast {
    var block = ast.Block.init();
    _ = self.lexer.next(); // Consume the curly brace as not to overflow the stack

    while (self.lexer.peek()) |tok| {
        if (tok.kind == .rcurly) break;

        const stmt = try self.parse_stmt();
        block.add_stmt(stmt);
    }

    if (self.lexer.peek() == null) {
        std.debug.print("Expected closing brace, found end of file\n", .{});
        return ParsingError.UnexpectedToken;
    }

    return block.ast();
}

fn parse_return(self: *Parser) ParsingError!ast.Ast {
    _ = try self.expect_next(.kw_return);

    const expr = try self.parse_expr();

    _ = try self.expect_next(.semicolon);

    return ast.Return.init(expr).ast();
}

fn parse_expr(self: *Parser) ParsingError!ast.Ast {
    const tok = self.lexer.peek();

    if (tok == null) {
        std.debug.print("Expected Statement, found end of file\n", .{});
        return ParsingError.ExpectedStatement;
    }

    if (tok.?.kind == .ident) {
        return self.parse_funcall();
    }

    return self.parse_number();
}

fn parse_funcall(self: *Parser) ParsingError!ast.Ast {
    const ident_tok = self.lexer.next(); // We don't need to check for null since we already checked

    _ = try self.expect_next(.lparen);
    const arg = try self.parse_expr();
    _ = try self.expect_next(.rparen);

    return ast.FuncCall.init(ident_tok.?.str, arg).ast();
}

fn parse_number(self: *Parser) ParsingError!ast.Ast {
    const tok = try self.expect_next(.integer);

    const num = std.fmt.parseInt(u64, tok.str, 10) catch unreachable;

    return ast.Integer.init(num).ast();
}

fn expect_next(self: *Parser, kind: Token.TokenKind) ParsingError!Token {
    const tok = self.lexer.next();

    if (tok == null) {
        std.debug.print("Expected {} but found end of file\n", .{kind});
        return ParsingError.UnexpectedToken;
    }

    if (tok.?.kind != kind) {
        std.debug.print("Expected {} but found {} instead\n", .{kind, tok.?.kind});
        return ParsingError.UnexpectedToken;
    }

    return tok.?;
}

fn expect_next_of(self: *Parser, kinds: []Token.TokenKind) ParsingError!Token {
    const tok = self.lexer.next();

    if (tok == null) {
        std.debug.print("Expected ", .{});
        for (kinds) |kind| {
            std.debug.print("{}, ", .{kind});
        }
        std.debug.print("but found end of file", .{});
        return ParsingError.UnexpectedToken;
    }

    const token = tok.?;

    for (kinds) |kind| {
        if (kind == token.kind) {
            return token;
        }
    }

    std.debug.print("Expected ", .{});
    for (kinds) |kind| {
        std.debug.print("{}, ", .{kind});
    }
    std.debug.print("but found {} instead\n", .{token.kind});
    return ParsingError.UnexpectedToken;
}
