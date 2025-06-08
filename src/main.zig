const std = @import("std");

const Parser = @import("Parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(alloc);

    defer {
        arena.deinit();

        if (gpa.deinit() == .leak) {
            std.log.err("{}\n", .{gpa.detectLeaks()});
        }
    }

    const src_file = try std.fs.cwd().openFile("star.c", .{});
    defer src_file.close();

    const src = try src_file.readToEndAlloc(alloc, 1024);
    defer alloc.free(src);

    var parser = Parser.init(src, &arena);

    const ast = try parser.parse();

    ast.emit();
}

// TODO: Update lexer and parser for new syntax
// TODO: Change backend to emit FASM instead of GAS
// TODO: External functions from Nomi (written in FASM)
// TODO: Add command line arguments
// TODO: Make the compiler emit object files assembled by FASM
// TODO: Start work on IR layer to abstract frontend and backend
// TODO: Start work on a type system
// TODO: Start work on user declared functions and calling user declared functions
// TODO: More types ("Strings")
// TODO: Variables
// TODO: Functions which takes args
// TODO: Hello, World!
