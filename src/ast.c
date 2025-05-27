#include "alloc.h"
#include "ast.h"

struct ast* ast_prog_new(struct ast*);
struct ast* ast_func_new(char*, struct ast*);
struct ast* ast_block_new(struct ast*);
struct ast* ast_funcall_new(char*, bool, i64);
struct ast* ast_integer_new(i64);

void ast_pprint(struct ast*);
