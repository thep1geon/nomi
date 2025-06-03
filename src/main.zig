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
