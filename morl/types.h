#ifndef TYPES_H
#define TYPES_H

#include "parser.h"

typedef enum c_type {
    C_I32, C_STRUCT,
} c_type;

typedef struct c_struct {
} c_struct;

typedef struct c_tuple {
} c_tuple;

typedef struct node {
    token *ident;
    c_type kind;
    bool taken;

    union {
        c_struct *s;
        c_tuple  *t;
    };
} node;

typedef struct type_env {
    node *nodes;

    size_t cap;
    size_t len_taken;
} type_env;

type_env *type_init(void);
void type_expand(type_env *env);
void type_insert(type_env *env, node n);
bool type_check();

#endif /* TYPES_H */
