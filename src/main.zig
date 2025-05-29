const std = @import("std");

const Parser = @import("Parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());

    defer {
        arena.deinit();

        if (gpa.deinit() == .leak) {
            std.log.err("{}\n", .{gpa.detectLeaks()});
        }
    }


    const src = 
        \\void main() {
        \\    putchar(42);
        \\}
        ;

    var parser = Parser.init(src, &arena);

    const ast = try parser.parse();

    ast.emit();
}
