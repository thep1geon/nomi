const std = @import("std");

const frontend = @import("frontend.zig");
const Lexer = frontend.lex.Lexer;
const Parser = frontend.Parser;

const cli = @import("cli.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(alloc);

    defer {
        arena.deinit();

        if (gpa.deinit() == .leak) {
            std.log.err("{}", .{gpa.detectLeaks()});
        }
    }

    const opts = try cli.parse_args();

    if (opts.early_exit) return;

    // Maybe just give the parser the file name and have it deal with.
    // Maybe separate the parser and lexer a little bit. The parser should not
    // have to know the name of the file the tokens it's parsing belongs to.
    // That is only the jon of the lexer.
    //
    // TODO: Make the lexer an argument passed into the parser

    var lexer = Lexer.init(opts.infile, alloc) catch |e| {
        std.log.err("{any}", .{e});
        std.log.err("Failed to initialzie the lexer", .{});
        return;
    };
    defer lexer.deinit();

    var parser = Parser.init(&lexer, arena.allocator());

    const ast = parser.parse() catch |e| { // We have bigger issues if this fails
        std.log.err("{any}", .{e});
        std.log.err("Failed to parse input file", .{});
        return;
    };

    var out_file = std.fs.cwd().createFile(opts.outfile, .{}) catch |e| {
        std.log.err("{any}", .{e});
        std.log.err("Failed to open the file {s}", .{opts.outfile});
        return;
    };
    defer out_file.close();

    ast.emit(out_file.writer()) catch |e| {
        std.log.err("{any}", .{e});
        std.log.err("Failed to emit assembly from ast", .{});
        return;
    };

    ast.deinit();

    const fasm_proc = std.process.Child.run(.{
        .allocator = alloc,
        .argv = &[_][]const u8{
            "fasm",
            opts.outfile,
            opts.outfile,
        },
    }) catch |e| {
        std.log.err("{any}", .{e});
        std.log.err("Failed to run FASM assembler or whatever", .{});
        return;
    };
    std.debug.print("{s}", .{fasm_proc.stderr});
    alloc.free(fasm_proc.stdout);
    alloc.free(fasm_proc.stderr);
}
