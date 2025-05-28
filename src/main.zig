const std = @import("std");

const lex = @import("lex.zig");
const Lexer = lex.Lexer;

pub fn main() !void {
    // TODO: Handle reading files into memory
    const src = "void main() {\n    putchar(42);\n}";

    var lexer = Lexer.init(src);

    while (lexer.next()) |tok| {
        tok.pprint();
    }
}

// TODO: Start parsing
