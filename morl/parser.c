#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "nob.h"
#include "parser.h"

bool is_literal(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c == '_');
}

bool is_number(char c) {
    return c >= '0' && c <= '9';
}

token next_token(const char *src, size_t *out_idx, int *out_line) {
    size_t idx = *out_idx;
    int line = *out_line;
    token_tag kind = M_EOF;

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
            case ',': kind = COMMA; break;
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
                continue;
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

bool tokenize(const char *src, tokens *toks) {
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

bool parse_literal(const char *source, const tokens *toks, stmts *nodes, size_t *pos) {
    // literal -> :  | =
    //               | type definition
    //               -> struct { | struct_name | 
    //
    //         -> :: | struct
    //               | () 
    //
    //         -> .  | literal 
    //               -> () | :: ()

    const token *vals = toks->items;

    // TODO: check out of bounds
    switch (vals[*pos + 1].kind) {
        case DB_COLON:
            if (vals[*pos + 2].kind != KW_STRUCT && vals[*pos + 2].kind != LPAREN) 
                return false;

            if (vals[*pos + 2].kind == KW_STRUCT) {
                m_struct s = { .ident = vals[*pos], .fields = {0}, .methods = {0}};
                *pos += 3;

                assert(vals[(*pos)++].kind == LBRACE);
            } else {

            }

            return true;
        case DOT:
            assert(vals[*pos + 2].kind == LITERAL);
            assert(vals[*pos + 3].kind == DB_COLON);

            // TODO parse method
            break;
        default: return false;
    }

    return true;
}

bool parse_stmt(const char *source, const tokens *toks, stmts *nodes, size_t *pos) {
    const token *vals = toks->items;

    printf("%zu\n", *pos);

    switch (vals[*pos].kind) {
        case LITERAL: return parse_literal(source, toks, nodes, pos);
        default:
            printf("\e[1;31mparser error:\e[0m unable to parse token `");
            for (int src = vals[*pos].start; src < vals[*pos].end; src++) {
                printf("%c", source[src]);
            }
            printf("`\n");
            return false;
    }

    printf("%d\n", toks->items[(*pos)++].line);
    return true;
}

bool parse(const char *source, const tokens *toks, stmts *nodes) {
    size_t pos = 0;

    while (pos < toks->count)
        if (!parse_stmt(source, toks, nodes, &pos)) 
            return false;

    return true;
}

