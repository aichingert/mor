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

token next_token(size_t *out_idx, int *out_line) {
    size_t idx = *out_idx;
    int line = *out_line;
    token_tag kind = M_EOF;

    while (SRC[idx] != '\0') {
        if (is_literal(SRC[idx])) {
            kind = LITERAL;
            size_t start = idx++;

            while(SRC[idx] != '\0' && is_alphanumeric(SRC[idx])) idx++;

            if (idx - start == 6 && strncmp(SRC + start, "struct", 6) == 0)
                kind = KW_STRUCT;
            else if (idx - start == 6 && strncmp(SRC + start, "return", 6) == 0)
                kind = KW_RETURN;
            else if (idx - start == 4 && strncmp(SRC + start, "self", 4) == 0)
                kind = KW_SELF;

            *out_idx = start;
            break;
        }

        if (is_number(SRC[idx])) {
            kind = NUMERAL;
            size_t start = idx++;

            while (SRC[idx] != '\0' && is_number(SRC[idx])) idx++;

            *out_idx = start;
            break;
        }

        switch (SRC[idx]) {
            case '+': 
                kind = PLUS; 
                if (SRC[idx + 1] != '\0' && SRC[idx + 1] == '=') {
                    idx++;
                    kind = PLUS_EQ;
                }
                break;
            case '-': 
                kind = MINUS; 
                if (SRC[idx + 1] != '\0') {
                    if (SRC[idx + 1] == '>') kind = ARROW;
                    else if (SRC[idx + 1] == '=') kind = MINUS_EQ;

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
                if (SRC[idx + 1] != '\0') {
                    if (SRC[idx + 1] == ':') kind = DB_COLON;
                    else if (SRC[idx + 1] == '=') kind = COLON_EQ;

                    if (kind != COLON) idx++;
                }
                break;
            case '\n': line++; [[fallthrough]];
            case ' ':
                idx += 1;
                *out_idx = idx;
                continue;
            default: 
                return (token){0, 0, 0, M_UNKNOWN};
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

bool tokenize(tokens *toks) {
    size_t idx = 0;
    int line = 1;

    if (SRC == NULL) printf("hmm\n");

    while (SRC[idx] != '\0') {
        token tok = next_token(&idx, &line);

        if (tok.kind == M_UNKNOWN) {
            printf("FAILED AT SYMBOL: '%c' [line=%d]\n", SRC[idx], line);
            return false;
        }

        nob_da_append(toks, tok);
    }

    return true;
}

void print_token(const token *tok) {
    for (int i = tok->start; i < tok->end; i++)
        printf("%c", SRC[i]);
}

void consume_and_assert(const tokens *toks, token_tag should_be, size_t *pos) {
    if (toks->items[*pos].kind != should_be) {

        printf("\e[1;31mparse error:\e[0m found `");
        print_token(&toks->items[*pos]);
        printf("` but expected %s on line %d\n", 
                TOKEN_TAG[should_be], 
                toks->items[*pos].line);
        exit(1);
    }

    if (++(*pos) >= toks->count) {
        printf("\e[1;31mparse error:\e[0m unexpected eof");
        exit(1);
    }
}

bool is_assign_op(const token *toks) {
    return toks->kind == EQ 
        || toks->kind == PLUS_EQ;
}

bool is_bin_op(const tokens *toks, size_t *pos) {
    if (*pos >= toks->count) return false;

    token_tag kind = toks->items[*pos].kind;
    return (kind == PLUS)
        || (kind == MINUS);
}

char get_bin_prec(const token *tok) {
    switch (tok->kind) {
        case PLUS: 
            return 10;
        case MINUS: 
            return 10;
        default:
            printf("\e[1;31mparse error:\e[0m expected binary operator but found `");
            print_token(tok);
            printf("` on line = %d\n", tok->line);
            exit(1);
    }
}

bool parse_type(const token *toks, size_t *pos, expr *ex) {
    //   -> struct | TODO: struct { ... } 
    //
    //   -> literal | = , ;

    if (toks[*pos].kind == KW_STRUCT) {
        printf("FATAL: compiler does not support anonymous structs\n");
        return false;
    }

    // primitives 
    int len = toks[*pos].end - toks[*pos].start;

    if (len == 3 && strncmp(SRC + toks[*pos].start, "i32", 3) == 0) {
        ex->v_expr->type = T_I32;
        ex->v_expr->type_ident = toks[(*pos)++];
        return true;
    }

    printf("%d\n", ex->v_expr == NULL);
    ex->v_expr->type = T_STRUCT;
    ex->v_expr->type_ident = toks[(*pos)++];
    return true;
}

bool parse_block(const tokens *toks, stmts *block, size_t *pos) {
    if (*pos + 1 >= toks->count) return false;

    consume_and_assert(toks, LBRACE, pos);

    while (*pos < toks->count && toks->items[*pos].kind != RBRACE)
        if (!parse_stmt(toks, block, pos)) 
            return false;

    consume_and_assert(toks, RBRACE, pos);
    return true;
}

bool parse_func(const tokens *toks, stmts *nodes, size_t *pos) {
    // self,
    // literal 
    // self.literal
    // literal.literal 
    // |-> :: ([params *[, params]]) [-> ret typ] 
    //     { [block] }

    const token *vals = toks->items;

    m_func *fn = (m_func*)calloc(1, sizeof(m_func));
    fn->ident = vals[*pos - 2];

    consume_and_assert(toks, LPAREN, pos);

    if (vals[*pos].kind == STAR || vals[*pos].kind == KW_SELF) {
        m_type t = T_SELF;

        if (vals[*pos].kind == STAR) {
            t = T_PTR_SELF;
            *pos += 1;
        }

        var *v = (var*)calloc(1, sizeof(var));
        v->type = t;

        nob_da_append(&fn->params, ((expr){ .kind = VAR, .v_expr = v}));
        consume_and_assert(toks, KW_SELF, pos);
    }

    while (*pos < toks->count && vals[*pos].kind != RPAREN) {
        print_token(&vals[*pos]);
        printf(" param list\n");
        break;
    }

    consume_and_assert(toks, RPAREN, pos);

    if (vals[*pos].kind == ARROW) {
        *pos += 1;
        expr *e = (expr*)calloc(1, sizeof(expr));
        e->kind = VAR;
        e->v_expr = (var*)malloc(sizeof(var));

        // EXPR -> since return type could be 
        // a future tuple \o/
        if (!parse_type(vals, pos, e)) 
            return false;
    }

    nob_da_append(nodes, ((stmt){ .kind = FUNCTION, .f = fn}));
    return parse_block(toks, &fn->body, pos);
}

bool parse_literal(const tokens *toks, stmts *nodes, size_t *pos) {
    // self,
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

            if (vals[*pos].kind == EQ || vals[*pos].kind == SEMI_COLON) 
                e->v_expr->type = T_INFER;
            else if (!parse_type(vals, pos, e)) 
                return false;

            if (vals[*pos].kind != EQ && vals[*pos].kind != SEMI_COLON) {
                printf("error: expected one of `=` or `;` on line = %d\n", vals[*pos].line);
                return false;
            }

            if (vals[*pos].kind == SEMI_COLON) {
                (*pos)++;
                nob_da_append(nodes, ((stmt){ .kind = EXPR, .e = e}));
                return true;
            }

            consume_and_assert(toks, EQ, pos);
            e->v_expr->ex = parse_expr(toks, pos, 0);
            consume_and_assert(toks, SEMI_COLON, pos);

            return true;
        case DB_COLON:
            if (vals[*pos].kind != KW_STRUCT && vals[*pos].kind != LPAREN) 
                return false;

            if (vals[*pos].kind == KW_STRUCT) {
                m_struct *ms = (m_struct*)calloc(1, sizeof(m_struct));
                ms->ident = vals[(*pos)++ - 2];
                ms->fields = (stmts){ .items = NULL, .count = 0, .capacity = 0, };

                consume_and_assert(toks, LBRACE, pos);

                while (*pos < toks->count) {
                    if (vals[*pos].kind == RBRACE) {
                        (*pos)++;

                        nob_da_append(nodes, ((stmt){ .kind = STRUCT, .s = ms }));
                        return true;
                    }

                    if (!parse_stmt(toks, &ms->fields, pos)) return false;
                }
            } else {
                
            }

            return true;
        case DOT:
            consume_and_assert(toks, LITERAL, pos);

            // literal.literal 
            //  |-> :: ()
            //  |-> ()
            //  |-> ASSIGN

            print_token(&vals[*pos]);

            if (vals[*pos].kind == DB_COLON) {
                printf("should be here\n");

            } else if (vals[*pos].kind == LPAREN) {
            } else if (is_assign_op(&vals[*pos])) {
                *pos += 1;
                expr *e = (expr*)calloc(1, sizeof(expr));
                e->kind = VAR;
                e->v_expr = (var*)calloc(1, sizeof(var));
                e->v_expr->ex    = parse_expr(toks, pos, 0);
                e->v_expr->type  = T_SELF;
                e->v_expr->ident = vals[*pos - 2];
                consume_and_assert(toks, SEMI_COLON, pos);
                return true;
            } [[fallthrough]];
        default: return false;
    }

    return true;
}

expr* parse_leading_expr(const tokens *toks, size_t *pos) {
    expr *ex = (expr*)calloc(1, sizeof(expr));

    // TODO: bounds checks
    print_token(&toks->items[*pos]);
    printf("\n");
    switch (toks->items[*pos].kind) {
        case NUMERAL:
            ex->kind = INT;
            ex->t_expr = &toks->items[(*pos)++];
            return ex;
        case LITERAL:
            printf("TODO: not implemented str expressions");
            exit(1);
        case DOT:
            // { [LITERAL = expr [, [*]]] }

            *pos += 1;
            ex->kind = DECL;
            ex->expres = (exprs*)calloc(1, sizeof(exprs));

            consume_and_assert(toks, LBRACE, pos);

            while (*pos < toks->count && toks->items[*pos].kind == LITERAL) {
                var *v = (var*)malloc(sizeof(var));

                consume_and_assert(toks, LITERAL, pos);
                consume_and_assert(toks, EQ, pos);

                v->ident = toks->items[*pos - 2];
                v->ex = parse_expr(toks, pos, 0);
                nob_da_append(ex->expres, ((expr){ .kind = VAR, .v_expr = v }));

                if (toks->items[*pos].kind != COMMA) break;
                *pos += 1;
            }

            consume_and_assert(toks, RBRACE, pos);
            return ex;
        case LBRACE:
            printf("TODO: block expression\n");
            exit(1);
        default:
            printf("error: expected one of `(` or expression on line = %d\n", toks->items[*pos].line);
            exit(1);
    }
}

expr* parse_expr(const tokens *toks, size_t *pos, char prec) {
    expr *ex = parse_leading_expr(toks, pos);

    while (toks->items[*pos].kind != M_EOF) {
        if (is_bin_op(toks, pos) && get_bin_prec(&toks->items[*pos]) >= prec) {
            bin *b = (bin*)calloc(1, sizeof(bin));
            b->lhs = ex;
            b->op = toks->items[*pos].kind;
            b->rhs = parse_expr(toks, pos, get_bin_prec(&toks->items[(*pos)++]));

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

bool parse_stmt(const tokens *toks, stmts *nodes, size_t *pos) {
    const token *vals = toks->items;

    switch (vals[*pos].kind) {
        case KW_SELF: [[fallthrough]];
        case LITERAL: 
            return parse_literal(toks, nodes, pos);
        case KW_RETURN:
            *pos += 1;
            nob_da_append(nodes, ((stmt){ .kind = RETURN, .e = parse_expr(toks, pos, 0)}));

            consume_and_assert(toks, SEMI_COLON, pos);
            return true;
        default:
            printf("\e[1;31mparser error:\e[0m unable to parse token `");
            print_token(&vals[*pos]);
            printf("` on line = %d\n", vals[*pos].line);
            return false;
    }

    printf("stmt on line = %d okay\n", toks->items[(*pos)++].line);
    return true;
}

bool parse(const tokens *toks, stmts *nodes) {
    size_t pos = 0;

    while (pos < toks->count)
        if (!parse_stmt(toks, nodes, &pos))
            return false;

    return true;
}

