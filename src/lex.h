#ifndef __LEX_H
#define __LEX_H

#include "string.h"

struct token {
    struct string lexeme;

    enum token_kind : u8 {
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
    /* @TASK(251217-163817): Introduce the notion of a location in a file for error messages */
};

const char* token_kind_to_cstr(enum token_kind kind);
void token_print(struct token token);

struct lexer {
    struct token token;
    struct string src;
    usize src_ptr;
    bool eof;
};

struct lexer lex(struct string program);
bool lexer_advance(struct lexer* lexer);

/* TASK(251219-170013): Add the ability to peek ahead into the next tokens */
/* TASK(251223-031459): Come up with an error scheme for the lexing of the source */

#endif  /*__LEX_H*/
