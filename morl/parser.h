#ifndef PARSER_H
#define PARSER_H

#include <stddef.h>

typedef enum {
    LITERAL, NUMERAL,

    // symbols
    LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET,

    // operations
    PLUS, MINUS,

    // keywords
    KW_STRUCT,

    M_EOF,
} token_tag;

typedef enum {
    // statements
    STRUCT,

    // expressions
    UNA, BIN,
} node_tag;

typedef struct {
    int start;
    int end;
    int line;

    token_tag kind;
} token;

typedef struct {
    token *items;
    size_t count;
    size_t capacity;
} tokens;

/*
struct node;

typedef struct {
    node left;
    node right;

    token_tag op;
} bin;

typedef struct {
    node n;
    token_tag op;
} una;

typedef struct {
    token ident;

    // TODO: fields
} struct_def;

typedef struct {
    node_tag kind;

    union {
        una u_expr;
        bin b_expr;

        struct_def s_stmt;
    }
} node;
*/

tokens tokenize(char *source);

//node* parse(token *tokens, size_t len);

#endif /* PARSER_H */
