const std = @import("std");
const Allocator = std.mem.Allocator;

// TODO: Pretty much nuke all of this.
//
// We need a better system for generating
// IR code than this implementation of the AST.
//
// After some reading of how Zig does it, I want to settle on something less
// polymorphic. I want a polymorphic `Node` type but a concrete `AST` type that
// we generate the IR from.
//
// The concrete AST type will hold the entire AST in itself. There will only be
// one AST object for each AST. The nodes will be different, holding different
// data and a tag.
//
// Like I mentioned earlier in this rationale, the main reason for doing this
// was a lack of cohesion between the `ast` and IR types. There is no good way
// to go from an AST to a list of IR in a clean manner with how we have things
// setup now. I am really liking how the IR is represented linearly, so I do not
// want to change that. I understand that this is just the first compiler of the
// bootstrap process, so none of this code will be used once we get a working Nomi
// compiler in Nomi, so I should not worry as much about it. But this is also a learning
// experience, and I want to write good code regardless of knowing that it will
// not be used after the Nomi compiler can compile itself.

// The structure to hold the entire Abstract Syntax Tree (AST, Ast). Only one instance of
// this structure will exist for each AST, although I do not think there will be more than
// one AST at once.

pub const Ast = struct {
    program: Program,
    alloc: Allocator,
};

// The actual node types that make up the AST

pub const Program = struct {
    declarations: std.ArrayList(Decl),
};

pub const Decl = union {
    func_decl: FuncDecl,
};

pub const FuncDecl = struct {
    name: []const u8,
    stmt: Stmt, 
};

pub const Stmt = union {
    block: Block,
    expr: Expr,
};

pub const Block = struct {
    statements = std.ArrayList(Stmt), 
};

pub const Expr = union {
    func_call: FuncCall,
    number: Number,
};

pub const FuncCall = struct {
    name: []const u8,
};

pub const Number = u64;
