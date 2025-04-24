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

bool is_alphanumeric(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c == '_') || (c >= '0' && c <= '9'); 
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

            while(src[idx] != '\0' && is_alphanumeric(src[idx])) idx++;

            if (idx - start == 6 && strncmp(src + start, "struct", 6) == 0) kind = KW_STRUCT;
            else if (idx - start == 6 && strncmp(src + start, "return", 6) == 0) kind = KW_RETURN;

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

void assert_kind(token expected, token_tag actual) {
    if (expected.kind != actual) {
        printf("\e[1;31mparse error:\e[0m on line = %d\n", expected.line);
        exit(1);
    }
}

bool is_bin_op(const tokens *toks, size_t *pos) {
    if (*pos >= toks->count) return false;

    token_tag kind = toks->items[*pos].kind;
    return (kind == PLUS)
        || (kind == MINUS);
}

char get_bin_prec(token tok) {
    switch (tok.kind) {
        case PLUS: 
            return 10;
        case MINUS: 
            return 10;
        default:
            printf("\e[1;31mparse error:\e[0m no bin token on line = %d\n", tok.line);
            exit(1);
    }
}

bool parse_type(const char *source, const token *toks, size_t *pos, expr *ex) {
    //   -> struct | TODO: struct { ... } 
    //
    //   -> literal | = , ;

    if (toks[*pos].kind == KW_STRUCT) {
        printf("FATAL: compiler does not support anonymous structs\n");
        return false;
    }

    // primitives 
    int len = toks[*pos].end - toks[*pos].start;

    if (len == 3 && strncmp(source + toks[*pos].start, "i32", 3) == 0) {
        ex->v_expr->type = T_I32;
        ex->v_expr->type_ident = toks[(*pos)++];
        return true;
    }

    ex->v_expr->type = T_STRUCT;
    ex->v_expr->type_ident = toks[(*pos)++];
    return true;
}

bool parse_block(const char *source, const tokens *toks, stmts *block, size_t *pos) {
    if (*pos + 1 >= toks->count) return false;

    assert_kind(toks->items[(*pos)++], LBRACE);

    while (*pos < toks->count && toks->items[*pos].kind != RBRACE)
        if (!parse_stmt(source, toks, block, pos)) 
            return false;

    assert_kind(toks->items[(*pos)++], RBRACE);
    return true;
}

bool parse_literal(const char *source, const tokens *toks, stmts *nodes, size_t *pos) {
    // literal -> :  | =
    //               | type definition
    //               -> struct { | struct_name | 
    //
    //         -> :: | struct
    //               | () 
    //               | !future constants!
    //
    //         -> .  | literal 
    //               -> () | :: ()

    const token *vals = toks->items;

    // TODO: check out of bounds
    *pos += 2;
    switch (vals[*pos - 1].kind) {
        case COLON:
            expr *e = (expr*)calloc(1, sizeof(expr));
            e->kind = VAR;
            e->v_expr = (var*)calloc(1, sizeof(var));
            e->v_expr->ident = vals[*pos - 2];

            if (vals[*pos].kind == EQ || vals[*pos].kind == SEMI_COLON) e->v_expr->type = T_INFER;
            else if (!parse_type(source, vals, pos, e)) return false;

            if (vals[*pos].kind != EQ && vals[*pos].kind != SEMI_COLON) {
                printf("error: expected one of `=` or `;` on line = %d\n", vals[*pos].line);
                return false;
            }

            if (vals[*pos].kind == SEMI_COLON) {
                (*pos)++;
                nob_da_append(nodes, ((stmt){ .kind = EXPR, .e = e}));
                return true;
            }

            assert(EQ == vals[(*pos)++].kind);
            e->v_expr->ex = parse_expr(toks, pos, 0);
            assert(SEMI_COLON == vals[(*pos)++].kind);

            return true;
        case DB_COLON:
            if (vals[*pos].kind != KW_STRUCT && vals[*pos].kind != LPAREN) 
                return false;

            if (vals[*pos].kind == KW_STRUCT) {
                m_struct *ms = (m_struct*)calloc(1, sizeof(m_struct));
                ms->ident = vals[(*pos)++ - 2];
                ms->fields = (stmts){ .items = NULL, .count = 0, .capacity = 0, };
                assert_kind(vals[(*pos)++], LBRACE);

                while (*pos < toks->count) {
                    if (vals[*pos].kind == RBRACE) {
                        (*pos)++;

                        nob_da_append(nodes, ((stmt){ .kind = STRUCT, .s = ms }));
                        return true;
                    }

                    if (!parse_stmt(source, toks, &ms->fields, pos)) return false;
                }
            } else {
                m_func *fn = (m_func*)calloc(1, sizeof(m_func));
                fn->ident = vals[*pos - 2];

                assert_kind(vals[(*pos)++], LPAREN);
                assert_kind(vals[(*pos)++], RPAREN);

                if (vals[*pos].kind == ARROW) {
                    expr *e = (expr*)calloc(1, sizeof(expr));
                    e->kind = VAR;
                    *pos += 1;

                    if (!parse_type(source, vals, pos, e)) 
                        return false;
                }

                printf("hello\n");
                if (!parse_block(source, toks, &fn->body, pos)) {
                    printf("ARGH\n");
                    return false;
                }

                printf("ARGH\n");
                printf("functions line = %d\n", vals[*pos].line);

                return false;
            }

            return true;
        case DOT:
            if (vals[*pos].kind != LITERAL 
                    || (vals[*pos + 1].kind != LPAREN && vals[*pos + 1].kind != DB_COLON))
                return false;

            if (vals[*pos + 1].kind == DB_COLON) {
                // method
            } else {
                // function call
            }

            return false;
        default: return false;
    }

    return true;
}

expr* parse_leading_expr(const tokens *toks, size_t *pos) {
    expr *ex = (expr*)calloc(1, sizeof(expr));

    // TODO: bounds checks
    switch (toks->items[*pos].kind) {
        case NUMERAL:
            ex->kind = INT;
            ex->t_expr = &toks->items[(*pos)++];
            return ex;
        case LITERAL:
            printf("TODO: not implemented str expressions");
            exit(1);
        default:
            printf("error: expected one of `(` or expression on line = %d\n", toks->items[*pos].line);
            exit(1);
    }
}

expr* parse_expr(const tokens *toks, size_t *pos, char prec) {
    expr *ex = parse_leading_expr(toks, pos);

    while (toks->items[*pos].kind != M_EOF) {
        if (is_bin_op(toks, pos) && get_bin_prec(toks->items[*pos]) >= prec) {
            bin *b = (bin*)calloc(1, sizeof(bin));
            b->lhs = ex;
            b->op = toks->items[*pos].kind;
            b->rhs = parse_expr(toks, pos, get_bin_prec(toks->items[(*pos)++]));

            expr *e = (expr*)calloc(1, sizeof(expr));
            e->kind = BIN;
            e->b_expr = b;
            ex = e;
            continue;
        }

        break;
    }

    return ex;
}

bool parse_stmt(const char *source, const tokens *toks, stmts *nodes, size_t *pos) {
    const token *vals = toks->items;

    printf("%zu\n", *pos);

    switch (vals[*pos].kind) {
        case LITERAL: 
            return parse_literal(source, toks, nodes, pos);
        case KW_RETURN:
            printf("\e[1;31mTODO\e[0m: ret %d\n", nodes == NULL);
            stmt *s = (stmt*)calloc(1, sizeof(stmt));
            //s->kind = RETURN;
            //s->e = parse_expr(toks, pos, 0);

            // TODO: implement return statement
            printf("\e[1;31mTODO\e[0m: ret\n");
            //nob_da_append(nodes, ((stmt){ .kind = RETURN, .e = parse_expr(toks, pos, 0)}));
            return true;
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

    printf("%zu\n", pos);
    return true;
}

