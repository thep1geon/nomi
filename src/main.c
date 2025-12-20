#include <stdio.h>

#define ENABLE_ASSERT
#include "base.h"

#include "lex.h"
#include "arena.h"
#include "string.h"

/* 
 * @TASK(251217-162901): Write the nomi compiler to compile (the bare minimum):
 *
 * func main() i32 {
 *     return 42;
 * }
 * */

struct ast_span {
    u32 start;
    u32 count;
};

struct ast {
    union {
        char* name;
        i64 number;

        struct ast_span decl_list; /* AST_PROGRAM will refer to this */
        struct ast_span stmt_list; /* AST_BLOCK will refer to this */

        /* @TASK(251219-204326): Add argument support to user-defined functions */
        struct {
            u32 symbol;
            u32 body;
        } func_decl;

        struct {
            u32 expr;
        } return_stmt;
    };

    u32 id; /* each ast node will know it's own id */

    enum ast_kind : u8 {
        AST_PROGRAM,
        AST_FUNCDECL,
        AST_RETURN,
        AST_NUMBER,
        AST_BLOCK,
        AST_SYMBOL,
        __ast_kind_count,
    } kind;

    u16 length;
};

bool ast_is_expr(struct ast ast) {
    switch (ast.kind) {
        case AST_NUMBER:
            return true;
        case AST_PROGRAM:
        case AST_FUNCDECL:
        case AST_RETURN:
        case AST_BLOCK:
            return false;
        case __ast_kind_count:
    }

    UNREACHABLE("ast_is_expr");
}

bool ast_is_stmt(struct ast ast) {
    switch (ast.kind) {
        case AST_PROGRAM:
        case AST_NUMBER:
            return false;
        case AST_FUNCDECL:
        case AST_RETURN:
        case AST_BLOCK:
            return true;
        case __ast_kind_count:
    }

    UNREACHABLE("ast_is_stmt");
}

i32 main(i32 argc, char** argv) {
    UNUSED(argc);
    UNUSED(argv);
    const char program[] = ""
        "func main() i32 {\n"
        "   return 42;\n"
        "}";

    struct lexer lexer = lex(STRING_FROM_PARTS(program, ARRLENGTH(program)));

    while (lexer_advance(&lexer)) {
        token_print(lexer.token);
    }

    puts("end of input.");

    puts("Sizeof: ");
    printf("  struct token:         %zu\n", sizeof (struct token));
    printf("  struct lexer:         %zu\n", sizeof (struct lexer));
    printf("  struct string:        %zu\n", sizeof (struct string));
    printf("  struct ast:           %zu\n", sizeof (struct ast));
    printf("  struct ast_span:      %zu\n", sizeof (struct ast_span));

    return 0;
}
