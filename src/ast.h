#ifndef __AST_H
#define __AST_H

struct ast {
    void (*pprint)(struct ast*);
};

struct ast_prog {
    struct ast ast;
    struct ast_func func;
};

struct ast_func { 
    struct ast ast;
    char* func_name;
    struct ast* stmt;
};

struct ast_block {
    struct ast ast;
    struct ast* stmt;
};

struct ast_funcall {
    struct ast ast;
    char* name;
    bool has_arg;
    u64 arg;
};

struct ast_integer {
    struct ast ast;
    i64 integer;
};

// Allocating the nodes and whatnot
struct ast* ast_prog_new(struct ast*);
struct ast* ast_func_new(char*, struct ast*);
struct ast* ast_block_new(struct ast*);
struct ast* ast_funcall_new(char*, bool, i64);
struct ast* ast_integer_new(i64);

// Pretty printing
// The pretty printers for each node type is in the ast.c file
void ast_pprint(struct ast*);

#endif  //__AST_H
