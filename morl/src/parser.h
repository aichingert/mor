#ifndef PARSER_H
#define PARSER_H

#include "darray.h"

typedef enum {
    // symbols
    lparen, rparen, lbrace, rbrace, lbracket, rbracket,

    // operations
    plus, minus,

    // keywords
    kw_struct

} tag;

typedef struct {
    int end;
    tag kind;
} token;


#endif /* PARSER_H */
