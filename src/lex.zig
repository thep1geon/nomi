const std = @import("std");

const Location = @import("Location.zig");

pub const Token = struct {
    const Self = @This();

    pub const Kind = enum {
        kw_void,
        kw_return,
        kw_i32,
        kw_func,

        lparen,
        rparen,
        lcurly,
        rcurly,
        semicolon,

        ident,
        integer,

        pub fn format(
            self: Kind,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = .{ fmt, options };
            try writer.print("{s}", .{switch (self) {
                .kw_void => "kw_void",
                .kw_return => "kw_return",
                .kw_i32 => "kw_i32",
                .kw_func => "kw_func",
                .lparen => "left paren",
                .rparen => "right paren",
                .lcurly => "left curly",
                .rcurly => "right curly",
                .semicolon => "semicolon",
                .ident => "ident",
                .integer => "integer",
            }});
        }
    };

    kind: Kind,
    str: []const u8, // The character slice that makes up the token
    loc: Location, // The location in the source code of this token

    pub fn init(kind: Kind, str: []const u8, loc: Location) Token {
        return .{
            .kind = kind,
            .str = str,
            .loc = loc,
        };
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = .{ fmt, options };
        try writer.print("{}: {{ {}, {s} }}", .{self.loc, self.kind, self.str});
    }
};

pub const Lexer = struct {
    pub const Error = error{
        EndOfFile,
        UnknownCharacter,
    };

    const Self = @This();

    err_loc: Location,  // The location set if we encounter an error. Useful if we find an error
                        // while peeking

    loc: Location,      // The Lexer also keeps a location. We will then copy this *updated* location
                        // to each new token we generate

    src: []const u8,    // Source code
    start: usize,       // Pointer to the first chacacter of the token
    ptr: usize,         // The pointer to the last character of the token we are lexing

    pub fn init(file_name: []const u8, src: []const u8) Lexer {
        return .{
            .src = src,
            .start = 0,
            .ptr = 0,
            .loc = .{ .line = 1, .column = 1, .file = file_name },
            .err_loc = .{ .line = 1, .column = 1, .file = file_name },
        };
    }

    pub fn next(self: *Self) Self.Error!Token {
        errdefer self.set_err_loc();
        self.skip_whitespace();

        self.start = self.ptr;
        
        const loc = self.loc;

        if (!self.is_bound()) {
            return Self.Error.EndOfFile;
        }

        switch (self.src[self.ptr]) {
            '0' ... '9' => {
                self.advance();

                while (self.is_bound() and std.ascii.isDigit(self.src[self.ptr])) {
                    self.advance();
                }

                return self.make_token(.integer, loc);
            },

            '(' => {
                self.advance();
                return self.make_token(.lparen, loc);
            },

            ')' => {
                self.advance();
                return self.make_token(.rparen, loc);
            },

            '{' => {
                self.advance();
                return self.make_token(.lcurly, loc);
            },

            '}' => {
                self.advance();
                return self.make_token(.rcurly, loc);
            },

            ';' => {
                self.advance();
                return self.make_token(.semicolon, loc);
            },

            // We've found an identifier
            'a' ... 'z', 'A' ... 'Z', '_' => {
                self.advance();

                while (self.is_bound() and std.ascii.isAlphanumeric(self.src[self.ptr])) {
                    self.advance();
                }

                // Check it against each of the keywords
                //
                // NOTE: We can move to a better system if this becomes too slow
                // or we have too many keywords to check against.
                if (std.mem.eql(u8, self.get_token_str(), "void")) {
                    return self.make_token(.kw_void, loc);
                } else if (std.mem.eql(u8, self.get_token_str(), "return")) {
                    return self.make_token(.kw_return, loc);
                } else if (std.mem.eql(u8, self.get_token_str(), "i32")) {
                    return self.make_token(.kw_i32, loc);
                } else if (std.mem.eql(u8, self.get_token_str(), "func")) {
                    return self.make_token(.kw_func, loc);
                }


                return self.make_token(.ident, loc);
            },

            else => {
                std.debug.print("Unknown character!\n", .{});
                return Self.Error.UnknownCharacter;
            },
        }

        unreachable;
    }

    pub fn peek(self: *Self) Self.Error!Token {
        errdefer self.set_err_loc();
        // Save the state of the lexer before fetching the next token
        const loc = self.loc;
        const ptr = self.ptr;
        // Restore the state of the lexer before the end of the function
        defer {
            self.ptr = ptr;
            self.loc = loc;
        }

        return self.next();
    }

    fn skip_whitespace(self: *Self) void {
        while (self.is_bound() and std.ascii.isWhitespace(self.src[self.ptr])) {
            if (self.src[self.ptr] == '\n') {
                self.loc.line += 1;
                self.loc.column = 0;
            }

            self.advance();
        }
    }

    inline fn advance(self: *Self) void {
        self.ptr += 1;
        self.loc.column += 1;
    }

    inline fn get_token_str(self: *Self) []const u8 {
        return self.src[self.start .. self.ptr];
    }

    inline fn make_token(self: *Self, kind: Token.Kind, loc: Location) Token {
        return Token.init(kind, self.get_token_str(), loc);
    }

    inline fn is_bound(self: *const Self) bool {
        return self.ptr < self.src.len;
    }

    inline fn set_err_loc(self: *Self) void {
        self.err_loc = self.loc;
    }
};
