const std = @import("std");
const lex = @import("lex.zig");

pub fn main() !void {
    const src = "void main() {\n    putchar(42);\n}";

    var lexer = lex.Lexer.init(src);

    while (lexer.next()) |tok| {
        std.debug.print("{} : {s}\n", .{tok.kind, tok.str});
    }
}
