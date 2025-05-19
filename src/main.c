#include <stdio.h>

#include "log.h"
#include "lex.h"

#define TOK_INFO 0

int main(void) {
    char* src = "void main() {\nputchar(42);\n}";
    struct token tok = {0};
    struct lexer lexer = lexer_init(src);

    while ((tok = lexer_next(&lexer)).type != TT_EOF) {
        LOG(TOK_INFO, TOK_FMT, TOK_ARG(tok));
    }

    return 0;
}
