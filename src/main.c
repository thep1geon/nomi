#include <stdio.h>

#define ENABLE_ASSERT
#include "base.h"

struct string {
    const char* cstr;
    usize length;
};

bool string_equal(struct string a, struct string b) {
    if (a.length != b.length) return false;
    return (memcmp(a.cstr, b.cstr, a.length) == 0);
}

#define STRING_FROM_PARTS(cstr, len) (struct string){cstr, len}

#define STRING(cstr) (struct string){cstr, strlen(cstr)}

#define TMPBUF_SIZE 32
static char tmpbuf[TMPBUF_SIZE] = {0};

/* 
 * @TASK(251217-162901): Write the nomi compiler to compile (the bare minimum):
 *
 * func main() i32 {
 *     return 42;
 * }
 * */

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

const char* token_kind_to_cstr(enum token_kind kind) {
    switch (kind) {
        case TOK_LPAREN: return "LPAREN"; break;
        case TOK_RPAREN: return "RPAREN"; break;
        case TOK_LCURLY: return "LCURLY"; break;
        case TOK_RCURLY: return "RCURLY"; break;
        case TOK_SEMICOLON: return "SEMICOLON"; break;
        case TOK_FUNC: return "FUNC"; break;
        case TOK_RETURN: return "RETURN"; break;
        case TOK_I32: return "I32"; break;
        case TOK_ID: return "ID"; break;
        case TOK_NUM: return "NUM"; break;
        case __token_kind_count: break;
    }

    UNREACHABLE("token_kind_to_cstr");
}

void token_print(struct token token) {
    snprintf(tmpbuf, TMPBUF_SIZE, "[%s]", token_kind_to_cstr(token.kind));
    printf("%-11s %.*s\n", tmpbuf, (i32)token.lexeme.length, token.lexeme.cstr);
}

struct lexer {
    struct string src;
    struct token token;
    usize src_ptr;
    bool eoi;
};

struct lexer lex(struct string program) {
    return (struct lexer) {
        .src = program,
        .token = (struct token){0},
        .src_ptr = 0,
        .eoi = 0,
    };
}

/* Just returns the current character */
static inline char peek_char(struct lexer* lexer) {
    if (lexer->src_ptr >= lexer->src.length) return '\0';
    return lexer->src.cstr[lexer->src_ptr];
}

/* Returns the current character and moves forward */
static inline char consume_char(struct lexer* lexer) {
    if (lexer->src_ptr >= lexer->src.length) return '\0';
    return lexer->src.cstr[lexer->src_ptr++];
}

static inline bool is_whitespace(char c) {
    switch (c) {
        case ' ':
        case '\n':
        case '\t':
        case '\r':
            return true;
        default:
            return false;
    }
}

static inline bool is_alpha(char c) {
    return (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            c == '_';
}

static inline bool is_numeric(char c) {
    return c >= '0' && c <= '9';
}

static inline bool is_alphanumeric(char c) {
    return is_alpha(c) || is_numeric(c);
}

static inline void skip_whitespace(struct lexer* lexer) {
    while (is_whitespace(peek_char(lexer))) {
        consume_char(lexer);
    }
}

static inline void make_lexeme(struct lexer* lexer, u32 lexeme_len) {
    lexer->token.lexeme = STRING_FROM_PARTS(lexer->src.cstr+lexer->src_ptr, lexeme_len);
    lexer->src_ptr += lexeme_len;
}

static inline void check_keyword(struct lexer* lexer) {
    if (string_equal(lexer->token.lexeme, STRING("i32"))) {
        lexer->token.kind = TOK_I32;
    } else if (string_equal(lexer->token.lexeme, STRING("func"))) {
        lexer->token.kind = TOK_FUNC;
    } else if (string_equal(lexer->token.lexeme, STRING("return"))) {
        lexer->token.kind = TOK_RETURN;
    }

    return;
}

static inline void make_id(struct lexer* lexer) {
    usize savepoint = lexer->src_ptr;
    u32 len = 0;
    while (is_alphanumeric(peek_char(lexer))) {
        consume_char(lexer);
        len++;
    }
    /* 
     * @TASK(251217-174254): See about simplifying this. It seems silly to have
     * to roll back the lexer just to push it forward again in the `make_lexem'
     * function
     * */
    lexer->src_ptr = savepoint;
    make_lexeme(lexer, len);

    check_keyword(lexer);
}

static inline void make_num(struct lexer* lexer) {
    usize savepoint = lexer->src_ptr;
    u32 len = 0;
    while (is_numeric(peek_char(lexer))) {
        len++;
        consume_char(lexer);
    }
    lexer->src_ptr = savepoint;
    make_lexeme(lexer, len);
}

bool lexer_advance(struct lexer* lexer) {
    char ch;

    if (lexer->eoi) return false;

    skip_whitespace(lexer);

    if (peek_char(lexer) == '\0') {
        lexer->eoi = true;
        return false;
    }

    switch (ch = peek_char(lexer)) {
        case '(':
            lexer->token.kind = TOK_LPAREN;
            make_lexeme(lexer, 1);
            break;
        case ')':
            lexer->token.kind = TOK_RPAREN;
            make_lexeme(lexer, 1);
            break;
        case '{':
            lexer->token.kind = TOK_LCURLY;
            make_lexeme(lexer, 1);
            break;
        case '}':
            lexer->token.kind = TOK_RCURLY;
            make_lexeme(lexer, 1);
            break;
        case ';':
            lexer->token.kind = TOK_SEMICOLON;
            make_lexeme(lexer, 1);
            break;
        default:
            if (is_alpha(ch)) {
                lexer->token.kind = TOK_ID;
                make_id(lexer);
            } else if (is_numeric(ch)) {
                lexer->token.kind = TOK_NUM;
                make_num(lexer);
            } else {
                UNIMPLEMENTED("Unknown character");
            }
    }

    return true;
}

i32 main(i32 argc, char** argv) {
    UNUSED(argc);
    UNUSED(argv);

    const char program[] = ""\
        "func main() i32 {\n"\
        "   return 42;\n"\
        "}";

    UNUSED(program);

    struct lexer lexer = lex(STRING_FROM_PARTS(program, ARRLENGTH(program)));

    while (lexer_advance(&lexer)) {
        token_print(lexer.token);
    }

    puts("end of input.");

    return 0;
}
