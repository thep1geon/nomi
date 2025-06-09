const std = @import("std");

const Parser = @import("Parser.zig");

const cli = @import("cli.zig");

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

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();


    const opts = try cli.parse_args(&args);

    const src_file = try std.fs.cwd().openFile(opts.input_path, .{});
    defer src_file.close();

    const src = try src_file.readToEndAlloc(alloc, 1024);
    defer alloc.free(src);

    var parser = Parser.init(src, &arena);

    const ast = try parser.parse();

    ast.emit();
}

// TODO: Make the compiler emit object files assembled by FASM
// TODO: Add location information for better errors
// TODO: External functions from Nomi (written in FASM)
// TODO: Start work on IR layer to abstract frontend and backend
// TODO: Start work on a type system
// TODO: Start work on user declared functions and calling user declared functions
// TODO: More types ("Strings")
// TODO: Variables
// TODO: Functions which takes args
// TODO: Hello, World!
