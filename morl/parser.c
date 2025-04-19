#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "nob.h"
#include "parser.h"

bool is_literal(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

bool is_number(char c) {
    return c >= '0' && c <= '9';
}

token next_token(char *src, size_t *out_idx, int *out_line) {
    size_t idx = *out_idx;
    int line = *out_line;
    token_tag kind = M_EOF;

tok_loop: 
    while (src[idx] != '\0') {
        if (is_literal(src[idx])) {
            kind = LITERAL;
            size_t start = idx++;

            while(src[idx] != '\0' && is_literal(src[idx])) idx++;

            if (idx - start > 5 && strncmp(src + start, "struct", 6) == 0) kind = KW_STRUCT;

            *out_idx = start;
            break;
        }

        if (is_number(src[idx])) {
            kind = NUMERAL;
            size_t start = idx++;

            while (src[idx] != '\0' && is_number(src[idx])) idx++;

            *out_idx = start;
            break;
        }

        switch (src[idx]) {
            case '+': 
                kind = PLUS;
                break;
            case '-': 
                kind = MINUS;
                break;
            case '\n': line++; [[fallthrough]];
            case ' ':
                idx += 1;
                *out_idx = idx;
                goto tok_loop;
            default: break;
        }

        if (kind != M_EOF) {
            idx++;
            break;
        }
    }

    token tok = { .line = line, .start = *out_idx, .end = idx, .kind = kind };
    *out_idx = idx;
    *out_line = line;
    return tok;
}

tokens tokenize(char *src) {
    size_t idx = 0;
    int line = 1;
    tokens toks = {0};

    while (src[idx] != '\0') {
        nob_da_append(&toks, next_token(src, &idx, &line));
    }

    return toks;
}

