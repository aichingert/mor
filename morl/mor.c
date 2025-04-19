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

        tokens toks = {0};
        if (!tokenize(src.items, &toks)) {
            printf("morl: \e[1;31mfatal error:\e[0m failed to tokenize %s\n", argv[i]);
            return 1;
        }



        nob_da_foreach(token, i, &toks) {
            int x = i - toks.items;
            if (x > 0 && toks.items[x - 1].line != i->line) printf("\n");

            for (int s = i->start; s < i->end; s++) {
                printf("%c", src.items[s]);
            }
        }
    }

    return 0;
}
