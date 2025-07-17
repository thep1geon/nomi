const std = @import("std");

const eql = std.mem.eql;
const Allocator = std.mem.Allocator;

const Error = error{
    UnrecognizedOption,
    MissingInfile,
};

const Option = struct {
    const ParseFn = fn () void;

    short_opt: []const u8,
    long_opt: ?[]const u8 = null,

    is_breaking: bool,

    parse_fn: ParseFn,

    inline fn init(is_breaking: bool, short: u8, long: ?[]const u8, parse_fn: ParseFn) Option {
        return .{
            .short_opt = &[_]u8{ '-', short },
            .long_opt = if (long) |l| "--" ++ l else null,
            .is_breaking = is_breaking,
            .parse_fn = parse_fn,
        };
    }

    fn check_arg(opt: *const Option, arg: []const u8) bool {
        if (opt.long_opt) |long| {
            return eql(u8, long, arg) or eql(u8, opt.short_opt, arg);
        }

        return eql(u8, opt.short_opt, arg);
    }

    fn attempt_parse_arg(opt: *const Option, arg: []const u8) bool {
        if (opt.check_arg(arg)) {
            opt.parse_fn();
            if (opt.is_breaking) util.breaking_flags = true;
            return opt.is_breaking;
        }

        return false;
    }
};

const util = struct {
    var breaking_flags = false;
    var executable: []const u8 = "";

    fn usage() void {
        std.debug.print("Usage: {s} [options...] <infile>\n", .{executable});
        return;
    }
};

pub fn help_fn() void {
    util.usage();
}

pub fn output_fn() void {
    std.debug.print("OUTPUT!!!\n", .{});
}

pub fn parse_args() Error![]const u8 {
    // FIXME: This is not cross platform. This code will not work on windows.
    // But I don't think I care >:)
    var args = std.process.args();
    defer args.deinit();

    var infile: []const u8 = "";

    const help = Option.init(true, 'h', "help", help_fn);
    const output = Option.init(true, 'o', "output", output_fn);

    const options = [_]Option{ help, output };

    // Grab the first arg which is always present
    util.executable = args.next() orelse unreachable;

    blk: while (args.next()) |arg| {
        inline for (options) |option| {
            // exit the whole while loop to stop parsing args
            if (option.attempt_parse_arg(arg)) break :blk;
        }

        if (infile.len == 0) {
            infile = arg;
        } else {
            util.usage();
            std.debug.print("Unrecognized option '{s}'\n", .{arg});
            return Error.UnrecognizedOption;
        }
    }

    if (infile.len == 0 and !util.breaking_flags) return Error.MissingInfile;

    return infile;
}
