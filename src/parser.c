#include "parser.h"

static inline struct token curr_token(struct parser* parser) {
    return parser->lexer.token;
}

bool parser_advance(struct parser* parser) {
    return lexer_advance(&parser->lexer);
}

bool parser_expect(struct parser* parser, enum token_kind kind) {
    if (!parser_advance(parser)) return false;
    return curr_token(parser).kind == kind;
}

u32 parser_add_node(struct parser* parser, struct node node) {
    u32 result = parser->nodes.length;
    node.id = result;
    DYNARRAY_APPEND(parser->nodes, node);
    return result;
}

u32 parser_reserve_node(struct parser* parser, enum node_kind kind) {
    struct node node = {0};
    node.kind = kind;
    return parser_add_node(parser, node);
}

void parser_append_nodeid_to_link(struct parser* parser, u32 link_node, u32 nodeid) {
    u32 next_link;
    u32 linkid;

    if (parser->nodes.at[link_node].link.ptr == 0) {
        parser->nodes.at[link_node].link = (struct node_link){ nodeid, 0 };
        return;
    }

    next_link = parser->nodes.at[link_node].link.next;

    while ((next_link = parser->nodes.at[link_node].link.next) != 0) {
        ASSERT(parser->nodes.at[next_link].kind == NODE_LINK);
        link_node = next_link;
    }

    linkid = parser_add_node(parser, node_create_link(nodeid, 0));
    parser->nodes.at[link_node].link.next = linkid;
}

/* TASK(251223-031434): Come up with an error scheme for parsing */

static inline u32 parse_block(struct parser* parser);
static inline u32 parse_number(struct parser* parser);
static inline u32 parse_expression(struct parser* parser);
static inline u32 parse_return(struct parser* parser);
static inline u32 parse_statement(struct parser* parser);
static inline u32 parse_symbol(struct parser* parser);
static inline u32 parse_func_decl(struct parser* parser);
static inline u32 parse_decl(struct parser* parser);

static inline u32 parse_block(struct parser* parser) {
    u32 block = parser_reserve_node(parser, NODE_BLOCK);

    while (!parser->lexer.eof && curr_token(parser).kind != TOK_RCURLY) {
        u32 statement = parse_statement(parser);
        parser_append_nodeid_to_link(parser, block, statement);
    }

    if (curr_token(parser).kind == TOK_RCURLY) {
        parser_advance(parser);
    }

    return block;
}

static inline u32 parse_number(struct parser* parser) {
    char buf[32] = {0};
    struct token tok = curr_token(parser);
    ASSERT(tok.kind == TOK_NUM);

    ASSERT(tok.lexeme.length < 32);
    memcpy(buf, tok.lexeme.cstr, tok.lexeme.length);
    i64 num = atoll(buf);
    return parser_add_node(parser, node_create_number(num));
}

static inline u32 parse_expression(struct parser* parser) {
    struct token tok = curr_token(parser);
    if (tok.kind == TOK_NUM) {
        return parse_number(parser);
    }

    TODO("The rest of them...");
}

static inline u32 parse_return(struct parser* parser) {
    u32 expression = parse_expression(parser);
    if (!parser_expect(parser, TOK_SEMICOLON)) TODO("EXPECTED ';'");
    parser_advance(parser);
    /* error checking and shit */
    return parser_add_node(parser, 
                           node_create_return(expression));
}

static inline u32 parse_statement(struct parser* parser) {
    struct token tok = curr_token(parser);
    if (tok.kind == TOK_LCURLY) {
        parser_advance(parser);
        return parse_block(parser);
    } else if (tok.kind == TOK_RETURN) {
        parser_advance(parser);
        return parse_return(parser);
    }

    TODO("the rest of them...");
}

static inline u32 parse_symbol(struct parser* parser) {
    struct token token = curr_token(parser);
    struct node node = node_create_symbol(token.lexeme.cstr, (u16)token.lexeme.length);
    return parser_add_node(parser, node);
}

static inline u32 parse_func_decl(struct parser* parser) {
    u32 sym, body;

    if (!parser_expect(parser, TOK_ID))     TODO("EXPECTED IDENTIFIER");

    sym = parse_symbol(parser);

    if (!parser_expect(parser, TOK_LPAREN)) TODO("EXPECTED '('");
    if (!parser_expect(parser, TOK_RPAREN)) TODO("EXPECTED ')'");
    if (!parser_expect(parser, TOK_I32))    TODO("EXPECTED 'i32'");

    parser_advance(parser);

    body = parse_statement(parser);

    return parser_add_node(parser, node_create_func_decl(sym, body));
}

static inline u32 parse_decl(struct parser* parser) {
    if (curr_token(parser).kind == TOK_FUNC) {
        return parse_func_decl(parser);
    }

    TODO("Other declarations");
}

struct ast parse(struct string src) {
    struct parser parser = {0};
    parser.lexer = lex(src);

    u32 root = parser_reserve_node(&parser, NODE_ROOT);

    if (!parser_advance(&parser)) {
        /* TASK(251223-032647): Handle the case of an empty source */
        TODO("Handle this error. See TASK(251223-032647)");
    }

    while (!parser.lexer.eof) {
        parser_append_nodeid_to_link(&parser, root, parse_decl(&parser));
    }

    return ast_from_node_list(parser.nodes);
}
