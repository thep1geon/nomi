const std = @import("std");

const Self = @This();

// NOTE: This is may be too small. But I can't imagine a file having more than
// 65k lines of code or more than 256 coloumns of code. In the event we need to
// increase these, it will be trivial to do so.

line: u16,
column: u8,
file: []const u8,

pub fn init(line: u16, column: u8, file: []const u8) Self {
    return .{
        .line = line,
        .coloumn = column,
        .file = file,
    };
}

pub fn pprint(self: Self) void {
    std.debug.print("{s}:{d}:{d}", .{ self.file, self.line, self.column });
}
