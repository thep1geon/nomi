#include <ctype.h>
#include <string.h>

#include "lex.h"
#include "log.h"

char* token_type_to_string(token_type tt) {
    static char* TT_lut[TT_COUNT] = {
        [TT_VOID] = "VOID",
        [TT_LPAREN] = "LPAREN",
        [TT_RPAREN] = "RPAREN",
        [TT_LCURLY] = "LCURLY",
        [TT_RCURLY] = "RCURLY",
        [TT_SEMICOLON] = "SEMICOLON",
        [TT_IDENT] = "IDENT",
        [TT_INTEGER] = "INTEGER",
        [TT_EOF] = "EOF",
    };

    return TT_lut[tt];
}


struct lexer lexer_init(char* src) {
    struct lexer lexer = (struct lexer){
        .src = src, 
        .ptr = src,
    };

    return lexer;
}

void skip_whitespace(struct lexer* lexer) {
    while (*lexer->ptr && isspace(*lexer->ptr)) {
        lexer->ptr++;
    }

    return;
}

// TODO: Implement the logic here to actually start lexing the tokens
struct token lexer_next(struct lexer* lexer) {
    struct token tok = {0};

    skip_whitespace(lexer);

    tok = (struct token){
        lexer->ptr, 
        lexer->ptr, 
        TT_EOF,
    };

    switch (*lexer->ptr) {
        case '(': 
            lexer->ptr++;
            tok.end = lexer->ptr;
            tok.type = TT_LPAREN; 
            break;
        case ')': 
            lexer->ptr++;
            tok.end = lexer->ptr;
            tok.type = TT_RPAREN;
            break;
        case '{': 
            lexer->ptr++;
            tok.end = lexer->ptr;
            tok.type = TT_LCURLY;
            break;
        case '}': 
            lexer->ptr++;
            tok.end = lexer->ptr;
            tok.type = TT_RCURLY;
            break;
        case ';': 
            lexer->ptr++;
            tok.end = lexer->ptr;
            tok.type = TT_SEMICOLON;
            break;
        case '\0':
            tok.type = TT_EOF;
            break;
        case '0':
        case '1': case '2': case '3':
        case '4': case '5': case '6':
        case '7': case '8': case '9':
            lexer->ptr++;
            while (isdigit(*lexer->ptr)) {
                lexer->ptr++;
            }
            tok.end = lexer->ptr;
            tok.type = TT_INTEGER;
            break;
        default:
            if (isalpha(*lexer->ptr)) {
                lexer->ptr++;
                while (isalnum(*lexer->ptr)) {
                    lexer->ptr++;
                }

                tok.end = lexer->ptr;

                if (strncmp(tok.start, "void", tok.end-tok.start) == 0) {
                    tok.type = TT_VOID;
                } else {
                    tok.type = TT_IDENT;
                }

                break;
            }

            LOG(LOG_ERROR, "Unknown character found: %c", *lexer->ptr);
    }

    return tok;
}
