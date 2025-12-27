#include "ast.h"

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
