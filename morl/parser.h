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
    KW_SELF,
    KW_STRUCT, 
    KW_RETURN,

    M_EOF, M_UNKNOWN_SYMBOL,
} token_tag;

typedef enum {
    // primitives 
    T_I32, 

    // user defined
    T_ANON_STRUCT, T_STRUCT,

    T_INFER,
} m_type;

typedef enum { 
    INT, FLOAT, STR, UNA, BIN, VAR, CALL
} expr_tag;

typedef enum {
    FUNCTION, STRUCT, BLOCK, EXPR, RETURN,
} stmt_tag;

typedef struct {
    int start;
    int end;
    int line;

    token_tag kind;
} token;

typedef struct tokens {
    token *items;
    size_t count;
    size_t capacity;
} tokens;

typedef struct exprs {
    struct expr *items;
    size_t count;
    size_t capacity;
} exprs;

typedef struct stmts {
    struct stmt *items;
    size_t count;
    size_t capacity;
} stmts;

typedef struct bin {
    struct expr *lhs;
    token_tag op;
    struct expr *rhs;
} bin;

typedef struct una {
    struct epxr *ex;
    token_tag op;
} una;

typedef struct var {
    token ident;
    m_type type;
    struct expr *ex;

    union {
        token type_ident;
        struct m_struct *str;
    };
} var;

typedef struct expr {
    expr_tag kind;

    union {
        una *u_expr;
        bin *b_expr;
        var *v_expr;
        token *t_expr;
    };
} expr;

typedef struct m_struct {
    token ident;
    stmts fields;
} m_struct;

typedef struct m_func {
    token ident;

    exprs params;
    stmts body;
    expr *return_type;
} m_func;

typedef struct stmt {
    stmt_tag kind;

    union {
        expr     *e;
        m_func   *f;
        stmts    *b; // <- BLOCK
        m_struct *s;
    };
} stmt;

bool tokenize(const char *source, tokens *toks);

bool parse(const char *source, const tokens *toks, stmts *nodes);
bool parse_stmt(const char *source, const tokens *toks, stmts *nodes, size_t *pos);
expr* parse_expr(const tokens *toks, size_t *pos, char prec);

#endif /* PARSER_H */
