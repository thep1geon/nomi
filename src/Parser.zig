const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const ast = @import("ast.zig");

const lex = @import("lex.zig");
const Token = lex.Token;
const Lexer = lex.Lexer;

const ParsingError = error{
    UnexpectedToken,
    ExpectedStatement,
};

const Parser = @This();

lexer: Lexer,
arena: *ArenaAllocator,
allocator: Allocator,

pub fn init(src: []const u8, arena: *ArenaAllocator) Parser {
    return .{
        .lexer = Lexer.init(src),
        .arena = arena,
        .allocator = arena.allocator(),
    };
}

pub fn parse(self: *Parser) !ast.Ast {
    return self.parse_program();
}

fn parse_program(self: *Parser) !ast.Ast {
    return ast.Program.init(self.allocator, try self.parse_decl()).ast();
}

fn parse_decl(self: *Parser) !ast.Ast {
    return self.parse_func_decl();
}

fn parse_func_decl(self: *Parser) !ast.Ast {
    _ = try self.expect_next(._void);
    
    const tok = try self.expect_next(.ident);

    _ = try self.expect_next(.lparen);
    _ = try self.expect_next(.rparen);

    const stmt = try self.parse_stmt();

    return ast.FuncDecl.init(self.allocator, tok.str, stmt).ast();
}

fn parse_stmt(self: *Parser) ParsingError!ast.Ast {
    const tok = self.lexer.peek();

    if (tok == null) {
        std.debug.print("Expected Statement, found end of file\n", .{});
        return ParsingError.ExpectedStatement;
    }

    if (tok.?.kind == .lcurly) {
        return self.parse_block();
    }

    const expr = try self.parse_expr();

    _ = try self.expect_next(.semicolon);

    return expr;
}

fn parse_block(self: *Parser) !ast.Ast {
    _ = self.lexer.next(); // Consume the curly brace as not to overflow the stack
    const stmt = try self.parse_stmt();

    _ = try self.expect_next(.rcurly);

    return ast.Block.init(self.allocator, stmt).ast();
}

fn parse_expr(self: *Parser) !ast.Ast {
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

fn parse_funcall(self: *Parser) !ast.Ast {
    const ident_tok = self.lexer.next(); // We don't need to check for null since we already checked

    _ = try self.expect_next(.lparen);
    const arg = try self.parse_number();
    _ = try self.expect_next(.rparen);

    return ast.Funcall.init(self.allocator, ident_tok.?.str, arg).ast();
}

fn parse_number(self: *Parser) !ast.Ast {
    const tok = try self.expect_next(.integer);

    const num = std.fmt.parseInt(u64, tok.str, 10) catch unreachable;

    return ast.Integer.init(self.allocator, num).ast();
}

fn expect_next(self: *Parser, kind: Token.TokenKind) !Token {
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
