#ifndef PARSER_H
#define PARSER_H

#include <stdbool.h>
#include <stddef.h>

typedef enum {
    LITERAL, NUMERAL,

    // symbols
    LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET,
    COLON, DB_COLON, COLON_EQ, SEMI_COLON,
    ARROW, STAR, DOT,

    // operations
    PLUS, MINUS, 
    EQ, MINUS_EQ, PLUS_EQ,

    // keywords
    KW_STRUCT,

    M_EOF, M_UNKNOWN_SYMBOL,
} token_tag;

typedef enum { 
    UNA, BIN, CALL 
} expr_tag;

typedef enum {
    BLOCK, DECLARE, ASSIGN,
} stmt_tag;

typedef enum {
    STRUCT, FUNCTION, METHOD,
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

typedef struct {
    struct expr *lhs;
    token_tag op;
    struct expr *rhs;
} bin;

typedef struct {
    struct epxr *ex;
    token_tag op;
} una;

typedef struct {
    struct expr *items;
    size_t count;
    size_t capacity;
} exprs;

typedef struct {
    struct node *items;
    size_t count;
    size_t capacity;
} stmts;

typedef struct {
    token ident;

    exprs fields;
    stmts methods;
} m_struct;

typedef struct {
    expr_tag kind;

    union {
        una u_expr;
        bin b_expr;
    };
} expr;

typedef struct {
    stmt_tag kind;

    union {
        /*
        declare d;
        function f;
        */
        m_struct s_stmt;
    };
} stmt;



// NODE: a node holds every possible type statement
// whereas a statement can be a function, declaration,
// ...
typedef struct {


} node;

bool tokenize(char *source, tokens *toks);

//node* parse(token *tokens, size_t len);

#endif /* PARSER_H */
