const std = @import("std");

const cli = @import("cli.zig");

const backend = @import("backend.zig");

const ir = backend.ir;

const frontend = @import("frontend.zig");

const Lexer = frontend.lex.Lexer;
const Parser = frontend.Parser;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(alloc);
    // const arena_alloc = arena.allocator();

    defer {
        arena.deinit();

        if (gpa.deinit() == .leak) {
            std.log.err("{}", .{gpa.detectLeaks()});
        }
    }

    var ir_list = ir.IrList.init(alloc);
    defer ir_list.deinit();

    try ir_list.list.append(ir.Stmt{ .func_decl = .{.name = "main" } });
    try ir_list.list.append(ir.Stmt{ .ret = .{.expr = .{ .integer = 42 } } });

    std.debug.print("{}\n", .{ ir_list });

    //
    // const opts = try cli.parse_args();
    //
    // if (opts.early_exit) return;
    //
    // var lexer = Lexer.init(opts.infile, alloc) catch |e| {
    //     std.log.err("{any}", .{e});
    //     std.log.err("Failed to initialzie the lexer", .{});
    //     return;
    // };
    // defer lexer.deinit();
    //
    // var parser = Parser.init(&lexer, arena_alloc);
    //
    // const ast = parser.parse() catch |e| { // We have bigger issues if this fails
    //     std.log.err("{any}", .{e});
    //     std.log.err("Failed to parse input file", .{});
    //     return;
    // };
    //
    // std.debug.print("{}\n", .{ast});
    //
    // var out_file = std.fs.cwd().createFile(opts.outfile, .{}) catch |e| {
    //     std.log.err("{any}", .{e});
    //     std.log.err("Failed to open the file {s}", .{opts.outfile});
    //     return;
    // };
    // defer out_file.close();
    //
    // ast.emit(out_file.writer()) catch |e| {
    //     std.log.err("{any}", .{e});
    //     std.log.err("Failed to emit assembly from ast", .{});
    //     return;
    // };
    //
    // ast.deinit(parser.allocator); // We no longer need the ast after this point
    //
    // // TODO: Roll our own custom assembler which assembles the IR directly
    // // to machine code based on the selected backend
    // //
    // // We need to ditch this dependency for a builtin assembler.
    // //
    // // A few reasons for this:
    // //
    // // 1. The more dependencies we have the more points of failure exist.
    // // 2. We can more easily compile directly into machine code if we
    // //    have a builtin assmbler.
    // // 3. We have more control over the assmebly process.
    // const fasm_proc = std.process.Child.run(.{
    //     .allocator = alloc,
    //     .argv = &[_][]const u8{
    //         "fasm",
    //         opts.outfile,
    //         opts.outfile,
    //     },
    // }) catch |e| {
    //     std.log.err("{any}", .{e});
    //     std.log.err("Failed to run FASM assembler or whatever", .{});
    //     return;
    // };
    // std.debug.print("{s}", .{fasm_proc.stderr});
    // alloc.free(fasm_proc.stdout);
    // alloc.free(fasm_proc.stderr);
}
