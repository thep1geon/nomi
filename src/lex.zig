const std = @import("std");

pub const Token = struct {
    pub const TokenKind = enum {
        _void,
        ident,
        lparen,
        rparen,
        lcurly,
        rcurly,
        integer,
        semicolon,
    };

    kind: TokenKind,
    str: []const u8, // The character slice that makes up the token

    pub fn init(kind: TokenKind, str: []const u8) Token {
        return .{
            .kind = kind,
            .str = str,
        };
    }
};

pub const Lexer = struct {
    const Self = @This();

    src: []const u8,    // Source code
    start: usize,       // Pointer to the first chacacter of the token
    ptr: usize,         // The pointer to the last character of the token we are lexing

    pub fn init(src: []const u8) Lexer {
        return .{
            .src = src,
            .start = 0,
            .ptr = 0,
        };
    }

    pub fn next(self: *Self) ?Token {
        if (self.ptr >= self.src.len) {
            return null;
        }

        self.skip_whitespace();

        self.start = self.ptr;

        switch (self.src[self.ptr]) {
            '0' ... '9' => {
                self.ptr += 1;

                while (self.ptr < self.src.len and std.ascii.isDigit(self.src[self.ptr])) {
                    self.ptr += 1;
                }

                return self.make_token(.integer);
            },

            '(' => {
                self.ptr += 1;
                return self.make_token(.lparen);
            },

            ')' => {
                self.ptr += 1;
                return self.make_token(.rparen);
            },

            '{' => {
                self.ptr += 1;
                return self.make_token(.lcurly);
            },

            '}' => {
                self.ptr += 1;
                return self.make_token(.rcurly);
            },

            ';' => {
                self.ptr += 1;
                return self.make_token(.semicolon);
            },

            'a' ... 'z', 'A' ... 'Z' => {
                self.ptr += 1;

                while (self.ptr < self.src.len and std.ascii.isAlphanumeric(self.src[self.ptr])) {
                    self.ptr += 1;
                }

                if (std.mem.eql(u8, self.get_token_str(), "void")) {
                    return self.make_token(._void);
                }

                return self.make_token(.ident);
            },

            else => {
                std.debug.print("Unknown character!\n", .{});
                return null;
            },
        }
    }

    fn skip_whitespace(self: *Self) void {
        while (std.ascii.isWhitespace(self.src[self.ptr])) {
            self.ptr += 1;
        }
    }

    inline fn get_token_str(self: *Self) []const u8 {
        return self.src[self.start .. self.ptr];
    }

    inline fn make_token(self: *Self, kind: Token.TokenKind) Token {
        return Token.init(kind, self.get_token_str());
    }
};
