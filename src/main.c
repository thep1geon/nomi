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

struct node_link {
    u32 ptr;
    u32 next;
};

struct node {
    union {
        const char* str;
        i64 number;

        struct node_link link;

        /* @TASK(251219-204326): Add argument support to user-defined functions */
        struct {
            u32 symbol;
            u32 body;
        } func_decl;

        struct {
            u32 expr;
        } return_stmt;
    };

    u32 id; /* each ast node will know it's own id */

    enum node_kind : u8 {
        NODE_ROOT,
        NODE_FUNCDECL,
        NODE_RETURN,
        NODE_NUMBER,
        NODE_BLOCK,
        NODE_SYMBOL,
        NODE_LINK,
        __node_kind_count,
    } kind;

    /* 
     * used for the str, but can also be used for anything else that requires a 
     * separate length field  */
    u16 length;

    u8 padding;
};

#define PARSE_ERROR UINT32_MAX

struct node_list {
    struct node* at;
    usize length;
    usize capacity;
};

struct node node_create_root(struct node_link link) {
    struct node node = {0};
    node.kind = NODE_ROOT;
    node.link = link;
    return node;
}

struct node node_create_func_decl(u32 symbol_node, u32 body) {
    struct node node = {0};
    node.kind = NODE_FUNCDECL;
    node.func_decl.symbol = symbol_node;
    node.func_decl.body = body;
    return node;
}

struct node node_create_block(struct node_link link) {
    struct node node = {0};
    node.kind = NODE_BLOCK;
    node.link = link;
    return node;
}

struct node node_create_return(u32 expr) {
    struct node node = {0};
    node.kind = NODE_RETURN;
    node.return_stmt.expr = expr;
    return node;
}

struct node node_create_number(i64 number) {
    struct node node = {0};
    node.kind = NODE_NUMBER;
    node.number = number;
    return node;
}

struct node node_create_symbol(const char* ptr, u16 length) {
    struct node node = {0};
    node.kind = NODE_SYMBOL;
    node.str = ptr;
    node.length = length;
    return node;
}

struct node node_create_link(u32 ptr, u32 next) {
    struct node node = {0};
    node.kind = NODE_LINK;
    node.link = (struct node_link){ ptr, next };
    return node;
}

struct ast {
    struct node* ptr;
    usize length;
};

struct ast ast_from_node_list(struct node_list nodes) {
    return (struct ast){
        .ptr    = nodes.at,
        .length = nodes.length,
    };
}

static inline void __indent(i32 indent) {
    for (i32 i = 0; i < indent * 2; ++i)
        putchar(' ');
}

void ast_pretty_print_node(struct ast* ast, struct node node, i32 indent);

void ast_pretty_print_link(struct ast* ast, struct node_link link, i32 indent) {
    struct node_link next_link;

    ast_pretty_print_node(ast, ast->ptr[link.ptr], indent);

    if (link.next == 0) return;

    ASSERT(ast->ptr[link.next].kind == NODE_LINK);
    next_link = ast->ptr[link.next].link;

    ast_pretty_print_link(ast, next_link, indent);
}

void ast_pretty_print_node(struct ast* ast, struct node node, i32 indent) {
    __indent(indent);
    switch (node.kind) {
        case NODE_ROOT:
            puts("root:");
            ASSERT(node.link.ptr != 0);
            ast_pretty_print_link(ast, node.link, indent+1);
            break;
        case NODE_FUNCDECL:
            puts("func_decl:");
            __indent(indent+1);
            puts("name:");
            ast_pretty_print_node(ast, ast->ptr[node.func_decl.symbol], indent+2);
            __indent(indent+1);
            puts("body:");
            ast_pretty_print_node(ast, ast->ptr[node.func_decl.body], indent+2);
            break;
        case NODE_RETURN:
            puts("return:");
            ast_pretty_print_node(ast, ast->ptr[node.return_stmt.expr], indent+1);
            break;
        case NODE_NUMBER:
            puts("number:");
            __indent(indent+1);
            printf("%ld\n", node.number);
            break;
        case NODE_BLOCK:
            puts("block:");
            ASSERT(node.link.ptr != 0);
            ast_pretty_print_link(ast, node.link, indent+1);
            break;
        case NODE_SYMBOL:
            puts("symbol:");
            __indent(indent+1);
            printf("%.*s\n", (i32)node.length, node.str);
            break;
        case NODE_LINK:
            UNREACHABLE("ast_pretty_print_node:NODE_LINK");
            break;
        case __node_kind_count:
            UNREACHABLE("ast_pretty_print_node:__node_kind_count");
            break;
    }
}

void ast_pretty_print(struct ast* ast) {
    ASSERT(ast->length > 0);
    struct node root = ast->ptr[0];

    ast_pretty_print_node(ast, root, 0);
}

struct parser {
    struct lexer lexer;
    struct node_list nodes;
};

static inline struct token curr_token(struct parser* parser) {
    return parser->lexer.token;
}

bool parser_eat(struct parser* parser) {
    return lexer_advance(&parser->lexer);
}

bool parser_expect(struct parser* parser, enum token_kind kind) {
    if (!parser_eat(parser)) return false;
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

/* @TASK(251223-031434): Come up with an error scheme for parsing */

u32 parse_statement(struct parser* parser);

u32 parse_block(struct parser* parser) {
    u32 block = parser_reserve_node(parser, NODE_BLOCK);

    while (!parser->lexer.eof && curr_token(parser).kind != TOK_RCURLY) {
        u32 statement = parse_statement(parser);
        parser_append_nodeid_to_link(parser, block, statement);

        parser_eat(parser);
    }

    if (curr_token(parser).kind == TOK_RCURLY) {
        parser_eat(parser);
    }

    return block;
}

u32 parse_number(struct parser* parser) {
    char buf[32] = {0};
    struct token tok = curr_token(parser);
    ASSERT(tok.kind == TOK_NUM);

    ASSERT(tok.lexeme.length < 32);
    memcpy(buf, tok.lexeme.cstr, tok.lexeme.length);
    i64 num = atoll(buf);
    return parser_add_node(parser, node_create_number(num));
}

u32 parse_expression(struct parser* parser) {
    struct token tok = curr_token(parser);
    if (tok.kind == TOK_NUM) {
        return parse_number(parser);
    }

    TODO("The rest of them...");
}

u32 parse_return(struct parser* parser) {
    u32 expression = parse_expression(parser);
    if (!parser_expect(parser, TOK_SEMICOLON)) TODO("...");
    /* error checking and shit */
    return parser_add_node(parser, 
                           node_create_return(expression));
}

u32 parse_statement(struct parser* parser) {
    struct token tok = curr_token(parser);
    if (tok.kind == TOK_LCURLY) {
        parser_eat(parser);
        return parse_block(parser);
    } else if (tok.kind == TOK_RETURN) {
        parser_eat(parser);
        return parse_return(parser);
    }

    TODO("the rest of them...");
}

u32 parse_symbol(struct parser* parser) {
    struct token token = curr_token(parser);
    struct node node = node_create_symbol(token.lexeme.cstr, (u16)token.lexeme.length);
    return parser_add_node(parser, node);
}

u32 parse_func_decl(struct parser* parser) {
    u32 sym, body;

    if (!parser_expect(parser, TOK_ID)) {
        TODO("Handle this error");
    }

    sym = parse_symbol(parser);

    if (!parser_expect(parser, TOK_LPAREN)) TODO("...");
    if (!parser_expect(parser, TOK_RPAREN)) TODO("...");
    if (!parser_expect(parser, TOK_I32))    TODO("...");

    parser_eat(parser);

    body = parse_statement(parser);

    return parser_add_node(parser, node_create_func_decl(sym, body));
}

u32 parse_decl(struct parser* parser) {
    if (curr_token(parser).kind == TOK_FUNC) {
        return parse_func_decl(parser);
    }

    TODO("Other declarations");
}

struct ast parse(struct string src) {
    struct parser parser = {0};
    parser.lexer = lex(src);

    u32 root = parser_reserve_node(&parser, NODE_ROOT);

    if (!lexer_advance(&parser.lexer)) {
        /* @TASK(251223-032647): Handle the case of an empty source */
        TODO("Handle this error. See @Task(251223-032647)");
    }

    while (!parser.lexer.eof) {
        parser_append_nodeid_to_link(&parser, root, parse_decl(&parser));
    }

    return ast_from_node_list(parser.nodes);
}

i32 main(i32 argc, char** argv) {
    UNUSED(argc);
    UNUSED(argv);
    const char src[] = "func foo() i32 {\n"
                       "   return 6;\n"
                       "}"
                       "func bar() i32 {\n"
                       "   return 7;\n"
                       "}";


    struct string program = STRING_FROM_PARTS(src, ARRLENGTH(src));

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
