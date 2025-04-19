#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define NOB_IMPLEMENTATION
#include "nob.h"
#include "parser.h"

int main(int argc, char **argv) {
    if (argc <= 1) {
        printf("morl: \e[1;31mfatal error:\e[0m no input file[s] provided\n");
        return 1;
    }

    for (int i = 1; i < argc; i++) {
        Nob_String_Builder src = {0};

        if (!nob_read_entire_file(argv[i], &src)) {
            printf("morl: \e[1;31mfatal error:\e[0m failed to read %s\n", argv[i]);
            return 1;
        }

        printf("[INFO] compiling: %s\n", src.items);

        tokens toks = tokenize(src.items);

        nob_da_foreach(token, i, &toks) {
            if (i->kind == NUMERAL) {
                printf("numeral -> ");
            } else if (i->kind == PLUS) {
                printf("+ -> ");
            } else if (i->kind == LITERAL) {
                printf("lit -> ");
            } else if (i->kind == M_EOF) {
                printf("eof -> ");
            } else if (i->kind == KW_STRUCT) {
                printf("struct -> ");
            }

            printf("line: %u | from: %u - to: %u\n", i->line, i->start, i->end);
        }
    }

    return 0;
}
