const std = @import("std");

const Parser = @import("Parser.zig");

const cli = @import("cli.zig");

// TODO: Improve error system for compiler internals.
// TODO: External functions from Nomi (written in FASM) (extern func sys_exit(i32) void;)
// TODO: Start work on IR layer to abstract frontend and backend
// TODO: Start work on a type system
// TODO: Start work on user declared functions and calling user declared functions
// TODO: More types ("Strings")
// TODO: Variables
// TODO: Functions which takes args
// TODO: Hello, World!
// TODO: Semantic Analysis (Ensuring functions return, etc.)

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

    var out_file = try std.fs.cwd().createFile(opts.output_path, .{});
    defer out_file.close();

    const src = try src_file.readToEndAlloc(alloc, 1024);
    defer alloc.free(src);

    var parser = Parser.init(opts.input_path, src, &arena);

    const ast = try parser.parse();

    ast.pprint();

    try ast.emit(out_file.writer());

    const fasm_proc = try std.process.Child.run(.{
        .allocator = alloc,
        .argv = &[_][]const u8{
            "fasm",
            opts.output_path,
            opts.output_path,
        },
    });
    defer alloc.free(fasm_proc.stdout);
    defer alloc.free(fasm_proc.stderr);
}
