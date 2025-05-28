const std = @import("std");

const lex = @import("lex.zig");
const Lexer = lex.Lexer;

const ast = @import("ast.zig");

pub fn main() !void {
    const src = "void main() {\n    putchar(42);\n}";

    var lexer = Lexer.init(src);

    while (lexer.next()) |tok| {
        tok.pprint();
    }

    var int = ast.Integer.init(42);
    var funcall = ast.Funcall.init("putchar", int.ast());
    var block = ast.Block.init(funcall.ast());

    var prog = ast.Program.init(
        ast.FuncDecl.init(
            "main", 
            block.ast(),
        ),
    );

    prog.ast().pprint();
}
