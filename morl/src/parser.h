#ifndef PARSER_H
#define PARSER_H

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

token* tokenize(char *source, size_t *out_len);

#endif /* PARSER_H */
