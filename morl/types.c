#include <stdlib.h>

#include "parser.h"
#include "types.h"

unsigned int djb2(char *buf, size_t buf_size)
{
    unsigned int hash = 5381;

    for (size_t i = 0; i < buf_size; ++i) {
        hash = ((hash << 5) + hash) + (unsigned int)buf[i]; /* hash * 33 + c */
    }

    return hash;
}

type_env *type_init(void) {
    type_env *env = (type_env*)calloc(1, sizeof(type_env));
    env->cap = 1500;
    return env;
}

void type_expand(type_env *env) {
    env->cap *= 2;

    node *prev = env->nodes;
    env->nodes = (node*)calloc(env->cap, sizeof(node));
    env->len_taken = 0;

    for (size_t i = 0; i < env->cap / 2; i++)
        if (prev[i].taken)
            type_insert(env, prev[i]);
}

int type_get_index(type_env *env, token *tok) {
    unsigned int idx = djb2(SRC + tok->start, tok->end - tok->start) % env->cap;

    // if type_env only gets modified by the designated 
    // functions it cannot happen that this leads to an 
    // infinite loop
    for (;; idx = (idx + 1) % env->cap) {
        if (!env->nodes[idx].taken) 
            return -1;

        token *ident = env->nodes[idx].ident;

        if (ident->start == tok->start && ident->end == tok->end) 
            return (int)idx;
    }
}

void type_insert(type_env *env, node n) {
    if (2 * env->len_taken >= env->cap)
        type_expand(env);

    int pos = type_get_index(env, n.ident);

    if (pos != -1) {
        env->nodes[pos] = n;
        return;
    }

    unsigned int idx = djb2(SRC + n.ident->start, n.ident->end - n.ident->start) % env->cap;

    for (;; idx = (idx + 1) % env->cap) {
        if (env->nodes[idx].taken) 
            continue;

        n.taken = true;
        env->nodes[idx] = n;
        return;
    }
}

bool type_check() {
    return true;
}
