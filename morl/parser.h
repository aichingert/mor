#ifndef PARSER_H
#define PARSER_H

#include <stdbool.h>
#include <stddef.h>

typedef enum {
    LITERAL, NUMERAL,

    // symbols
    LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET,
    COLON, DB_COLON, COLON_EQ, SEMI_COLON, 
    COMMA, ARROW, STAR, DOT,

    // operations
    PLUS, MINUS, 
    EQ, MINUS_EQ, PLUS_EQ,

    // keywords
    KW_STRUCT,

    M_EOF, M_UNKNOWN_SYMBOL,
} token_tag;

typedef enum {
    // primitives 
    T_I32, 

    // user defined
    T_ANON_STRUCT, T_STRUCT,
} m_type;

typedef enum { 
    UNA, BIN, VAR, CALL
} expr_tag;

typedef enum {
    FUNCTION, STRUCT, BLOCK, DECLARE, ASSIGN,
} stmt_tag;

typedef struct {
    struct expr *items;
    size_t count;
    size_t capacity;
} exprs;

typedef struct {
    struct stmt *items;
    size_t count;
    size_t capacity;
} stmts;

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
    token ident;
    m_type type;

    union {
        token *type_ident;
        struct m_struct *str;
    };
} var;

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
        var v_expr;
    };
} expr;

typedef struct {
    stmt_tag kind;

    union {
        /*
        declare d;
        function f;
        */
        m_struct *s_stmt;
    };
} stmt;

bool tokenize(const char *source, tokens *toks);
bool parse(const char *source, const tokens *toks, stmts *nodes);

#endif /* PARSER_H */
