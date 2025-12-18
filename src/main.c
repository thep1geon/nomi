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

i32 main(i32 argc, char** argv) {
    UNUSED(argc);
    UNUSED(argv);

    const char program[] = ""   \
        "func main() i32 {\n"   \
        "   return 42;\n"       \
        "}";

    struct lexer lexer = lex(STRING_FROM_PARTS(program, ARRLENGTH(program)));

    while (lexer_advance(&lexer)) {
        token_print(lexer.token);
    }

    puts("end of input.");

    return 0;
}
