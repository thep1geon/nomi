#define ENABLE_ASSERT
#include "base.h"

#include "arena.h"
#include "string.h"
#include "lex.h"
#include "parser.h"

/* TASK(251227-124400): Add compilation from files instead of a string */

#define femit(f, ...) STATEMENT( fprintf(f, __VA_ARGS__); fprintf(f, "\n"); )

void emit_return(FILE* file, struct ast* ast, struct node node) {
    UNUSED(ast);
    femit(file, "    mov $%ld, %%rax", node.number);
    femit(file, "    ret");
}

void emit_statement(FILE* file, struct ast* ast, struct node node) {
    if (node.kind == NODE_RETURN) {
        emit_return(file, ast, ast->ptr[node.return_stmt.expr]);
    }
}

void emit_func_decl(FILE* file, struct ast* ast, struct node node) {
    struct node sym, body;

    sym = ast->ptr[node.func_decl.symbol];
    body = ast->ptr[node.func_decl.body];

    femit(file, "%.*s:", (i32)sym.length, sym.str);

    emit_statement(file, ast, body);
}

void code_gen(struct ast* ast) {
    FILE* outfile = fopen("main.s", "wb");

    struct node root = ast->ptr[0];
    femit(outfile, "    .text");
    femit(outfile, "    .globl main");

    struct node_link link = root.link;
    struct node decl = ast->ptr[link.ptr];

    emit_func_decl(outfile, ast, decl);

    while (link.next != 0) {
        link = ast->ptr[link.next].link;
        decl = ast->ptr[link.ptr];

        emit_func_decl(outfile, ast, decl);
    }

    fclose(outfile);
}

i32 main(i32 argc, char** argv) {
    UNUSED(argc);
    UNUSED(argv);
    const char src[] = "func main() i32\n"
                       "    return 42;";

    struct string program = STRING_LIT(src);

    /* 
     * TASK(251223-040819): Introduce flags to print various aspects of the
     * compiler as its running.
     * */

    struct lexer lexer = lex(program);

    while (lexer_advance(&lexer)) {
        token_print(lexer.token);
    }

    puts("end of input.");

    struct ast ast = parse(program);
    ast_pretty_print(&ast);

    code_gen(&ast);

    free(ast.ptr);

    return 0;
}
