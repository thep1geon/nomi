#ifndef __LEX_H
#define __LEX_H

#include "util.h"

typedef enum {
    TT_VOID,
    TT_LPAREN,
    TT_RPAREN,
    TT_LCURLY,
    TT_RCURLY,
    TT_SEMICOLON,

    TT_IDENT,
    TT_INTEGER,

    TT_EOF,
    TT_COUNT,
} token_type;

struct token {
    char* start;
    char* end;
    token_type type;   
};

#define TOK_FMT "[%.*s ~ %s]"
#define TOK_ARG(t) (i32)((t).end-(t).start), (t).start, token_type_to_string((t).type)

char* token_type_to_string(token_type);

struct lexer {
    char* src;
    char* ptr;
};

struct lexer lexer_init(char*);
struct token lexer_next(struct lexer*);

#endif  //__LEX_H
