#ifndef __AST_H
#define __AST_H

#include "base.h"

struct node_link {
    u32 ptr;
    u32 next;
};

struct node {
    union {
        const char* str;
        i64 number;

        struct node_link link;

        /* TASK(251219-204326): Add argument support to user-defined functions */
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

struct node_list {
    struct node* at;
    usize length;
    usize capacity;
};

struct node node_create_root(struct node_link link);
struct node node_create_func_decl(u32 symbol_node, u32 body);
struct node node_create_block(struct node_link link);
struct node node_create_return(u32 expr);
struct node node_create_number(i64 number);
struct node node_create_symbol(const char* ptr, u16 length);
struct node node_create_link(u32 ptr, u32 next);

struct ast {
    struct node* ptr;
    usize length;
};

struct ast ast_from_node_list(struct node_list nodes);
void ast_pretty_print_link(struct ast* ast, struct node_link link, i32 indent);
void ast_pretty_print_node(struct ast* ast, struct node node, i32 indent);
void ast_pretty_print(struct ast* ast);

#endif  /*__AST_H*/
