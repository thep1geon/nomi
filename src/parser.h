#ifndef __PARSER_H
#define __PARSER_H

#include "base.h"
#include "lex.h"
#include "ast.h"

/* 
 * Since we're dealing with u32 indices instead of pointers,
 * we need a number to represent that an error has occured. We
 * can use UINT32_MAX for that.
 * */
#define PARSE_ERROR UINT32_MAX

struct parser {
    struct lexer lexer;
    struct node_list nodes;
};

bool parser_advance(struct parser* parser);
bool parser_expect(struct parser* parser, enum token_kind kind);
u32 parser_add_node(struct parser* parser, struct node node);
u32 parser_reserve_node(struct parser* parser, enum node_kind kind);
void parser_append_nodeid_to_link(struct parser* parser, u32 link_node, u32 nodeid);

/* TASK(251223-031434): Come up with an error scheme for parsing */

struct ast parse(struct string src);

#endif  /*__PARSER_H*/
