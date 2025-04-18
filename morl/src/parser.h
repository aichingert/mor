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
} tag;

typedef struct {
    int start;
    int end;
    int line;

    tag kind;
} token;

token* tokenize(char *source, size_t *out_len);

#endif /* PARSER_H */
