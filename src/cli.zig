const std = @import("std");
const ArgIterator = std.process.ArgIterator;

const CLIError = error {
    MissingInputFilePath,
    TooManyOptions,
};

const options = struct {
    // More of an outline
    const NomiOptionsTemplate = struct {
        input_path: ?[]const u8 = null,
        output_path: ?[]const u8 = null,
    };

    // Guarantees
    const NomiOptions = struct {
        input_path: []const u8 = "",
        output_path: []const u8 = "",
    };

    pub fn finalize(opts: NomiOptionsTemplate) CLIError!NomiOptions {
        var final_opts = NomiOptions{};

        final_opts.input_path = opts.input_path orelse {
            std.debug.print("Missing input file path.\n", .{});
            return CLIError.MissingInputFilePath;
        };

        final_opts.output_path = opts.output_path orelse "output.o";

        return final_opts;
    }
};

pub fn print_usage() void {
    const help = 
        \\Usage:
        \\      nomic <input-file> [output-file]
        \\      
        \\      output-file defaults to "output.o" if nothing is provided
        ;

    std.debug.print("{s}\n", .{help});
    return;
}

pub fn parse_args(args: *ArgIterator) CLIError!options.NomiOptions {
    var opts = options.NomiOptionsTemplate{};

    // Skip the first arg, which is the compiler
    _ = args.skip();

    while (args.next()) |arg| {
        if (opts.input_path == null) {
            opts.input_path = arg;
        } else if (opts.input_path != null and opts.output_path == null) {
            opts.output_path = arg;
        } else {
            std.debug.print("Too many options.\n", .{});
            return CLIError.TooManyOptions;
        }
    }

    return options.finalize(opts);
}
