const std = @import("std");

const mem = std.mem;

const Allocator = std.mem.Allocator;
const ArgIterator = std.process.ArgIterator;

const Error = error{
    UnrecognizedOption,
    MissingInfile,
};

const util = struct {
    var breaking_flags = true;
    var executable: []const u8 = "";

    fn usage() void {
        std.debug.print("Usage: {s} [options...] <infile>\n", .{executable});
        return;
    }
};

pub const Options = struct {
    infile: []const u8 = "",
    outfile: []const u8 = "output.o",

    early_exit: bool = false,
};

pub fn parse_args() Error!Options {
    var opts = Options{};

    // FIXME: This is not cross platform. This code will not work on windows.
    // But I don't think I care >:)
    var args = std.process.args();
    defer args.deinit();

      // Grab the first arg which is always present
    util.executable = args.next() orelse unreachable;

    blk: while (args.next()) |arg| {
        if (mem.eql(u8, arg, "-h") or mem.eql(u8, arg, "--help")) {
            util.usage();
            break :blk;
        } else if (mem.eql(u8, arg, "-o") or mem.eql(u8, arg, "--output")) {
            // FIXME: Deal with actual error handling here
            opts.outfile = args.next() orelse @panic("Expected outfile");
        } else if (opts.infile.len == 0 and arg[0] != '-') {
            opts.infile = arg;
        } else {
            util.usage();
            std.debug.print("Unrecognized option '{s}'\n", .{arg});
            return Error.UnrecognizedOption;
        }
    } else {
        util.breaking_flags = false;
    }

    opts.early_exit = util.breaking_flags;

    if (opts.infile.len == 0 and !util.breaking_flags) return Error.MissingInfile;

    return opts;
}
