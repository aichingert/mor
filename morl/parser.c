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

            if (idx - start == 6 && strncmp(src + start, "struct", 6) == 0) kind = KW_STRUCT;

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
            case '+': kind = PLUS; break;
            case '-': 
                kind = MINUS; 
                if (src[idx + 1] != '\0') {
                    if (src[idx + 1] == '>') kind = ARROW;
                    else if (src[idx + 1] == '=') kind = MINUS_EQ;

                    if (kind != MINUS) idx++;
                }
                break;
            case '*': kind = STAR; break;
            case '=': kind = EQ; break;
            case '.': kind = DOT; break;
            case '(': kind = LPAREN; break;
            case ')': kind = RPAREN; break;
            case '{': kind = LBRACE; break;
            case '}': kind = RBRACE; break;
            case ';': kind = SEMI_COLON; break;
            case ':':
                kind = COLON;
                if (src[idx + 1] != '\0') {
                    if (src[idx + 1] == ':') kind = DB_COLON;
                    else if (src[idx + 1] == '=') kind = COLON_EQ;

                    if (kind != COLON) idx++;
                }
                break;
            case '\n': line++; [[fallthrough]];
            case ' ':
                idx += 1;
                *out_idx = idx;
                goto tok_loop;
            default: 
                return (token){0, 0, 0, M_UNKNOWN_SYMBOL};
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

bool tokenize(char *src, tokens *toks) {
    size_t idx = 0;
    int line = 1;

    while (src[idx] != '\0') {
        token tok = next_token(src, &idx, &line);

        if (tok.kind == M_UNKNOWN_SYMBOL) {
            printf("FAILED AT SYMBOL: '%c' [line=%d]\n", src[idx], line);
            return false;
        }

        nob_da_append(toks, tok);
    }

    return true;
}

