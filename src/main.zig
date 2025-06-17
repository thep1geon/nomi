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

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(alloc);

    defer {
        arena.deinit();

        if (gpa.deinit() == .leak) {
            std.log.err("{}", .{gpa.detectLeaks()});
        }
    }

    var args = std.process.argsWithAllocator(alloc) catch |e| { // We have bigger issues if this fails
        std.log.err("{any}", .{e});
        std.log.err("Failed to allocate args or whatever", .{});
        return;
    };
    defer args.deinit();

    const opts = cli.parse_args(&args) catch |e| {
        std.log.err("{any}", .{e});
        cli.print_usage();
        return;
    };

    const src_file = std.fs.cwd().openFile(opts.input_path, .{}) catch |e| {
        std.log.err("{any}", .{e});
        std.log.err("Failed to open the file {s}", .{opts.input_path});
        return;
    };
    defer src_file.close();

    var out_file = std.fs.cwd().createFile(opts.output_path, .{}) catch |e| {
        std.log.err("{any}", .{e});
        std.log.err("Failed to open the file {s}", .{opts.output_path});
        return;
    };
    defer out_file.close();

    const src = src_file.readToEndAlloc(alloc, 1024) catch |e| { // We have bigger issues if this fails
        std.log.err("{any}", .{e});
        std.log.err("Failed to read source file or whatever", .{});
        return;
    };
    defer alloc.free(src);

    var parser = Parser.init(opts.input_path, src, &arena);

    const ast = parser.parse()  catch |e| { // We have bigger issues if this fails
        std.log.err("{any}", .{e});
        std.log.err("Failed to parse input file", .{});
        return;
    };

    ast.emit(out_file.writer()) catch |e| {
        std.log.err("{any}", .{e});
        std.log.err("Failed to emit assembly from ast", .{});
        return;
    };

    const fasm_proc = std.process.Child.run(.{
        .allocator = alloc,
        .argv = &[_][]const u8{
            "fasm",
            opts.output_path,
            opts.output_path,
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
