#define ENABLE_ASSERT
#include "base.h"

#include "arena.h"
#include "string.h"
#include "lex.h"
#include "parser.h"

/* 
 * TASK(251217-162901): Write the nomi compiler to compile (the bare minimum):
 *
 * func main() i32 {
 *     return 42;
 * }
 * */


/* TASK(251223-040949): Move the parser code into separate module */

i32 main(i32 argc, char** argv) {
    UNUSED(argc);
    UNUSED(argv);
    // const char src[] = "func main() i32 return 42;";
    const char src[] = "func main() i32 return 42;";


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

    free(ast.ptr);

    return 0;
}
