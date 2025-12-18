#ifndef __LEX_H
#define __LEX_H

#include "string.h"

struct token {
    enum token_kind {
        TOK_LPAREN,
        TOK_RPAREN,
        TOK_LCURLY,
        TOK_RCURLY,
        TOK_SEMICOLON,

        TOK_FUNC,
        TOK_RETURN,
        TOK_I32,

        TOK_ID,
        TOK_NUM,

        __token_kind_count,
    } kind;

    struct string lexeme;
    /* @TASK(251217-163817): Introduce the notion of a location in a file for error messages */
};

const char* token_kind_to_cstr(enum token_kind kind);
void token_print(struct token token);

struct lexer {
    struct string src;
    struct token token;
    usize src_ptr;
    bool eoi;
};

struct lexer lex(struct string program);
bool lexer_advance(struct lexer* lexer);

#endif  /*__LEX_H*/
