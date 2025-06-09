const std = @import("std");
const ArgIterator = std.process.ArgIterator;

const NomiOptions = struct {
    input_path: []const u8,
};

const CLIError = error {
    MissingInputFile,
    TooManyArgs,
};

fn str_eql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    if (a.len == 0 or a.ptr == b.ptr) return true;

    for (a, b) |a_elem, b_elem| {
        if (a_elem != b_elem) return false;
    }
    return true;
}


pub fn print_usage() void {
    const help = 
        \\Usage:
        \\      nomic <input-file>
        ;

    std.debug.print("{s}\n", .{help});
    return;
}

pub fn parse_args(args: *ArgIterator) !NomiOptions {
    var input_path: ?[]const u8 = null;

    // Skip the first arg, which is the compiler
    _ = args.skip();

    // We only support 1 file being passed into the compiler and no args
    while (args.next()) |arg| {
        if (input_path != null) {
            std.debug.print("Too many options\n", .{});
            print_usage();
            return CLIError.TooManyArgs;
        }

        input_path = arg; 
    }

    if (input_path == null) {
        std.debug.print("Missing input file.\n", .{});
        print_usage();
        return CLIError.MissingInputFile;
    }

    return NomiOptions{
        .input_path = input_path.?,
    };
}
