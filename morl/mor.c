#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define NOB_IMPLEMENTATION
#include "nob.h"
#include "parser.h"

char *SRC = NULL;

bool read_file(char *file_name) {
    FILE *file = fopen(file_name, "rb");
    if (file == NULL) return false;

    if (fseek(file, 0, SEEK_END) != 0) return false;
    long file_size = ftell(file);
    if (fseek(file, 0, SEEK_SET) != 0) return false;

    SRC = malloc(file_size + 1);

    fread(SRC, file_size, 1, file);
    SRC[file_size] = 0;
    fclose(file);

    return true;
}

int main(int argc, char **argv) {
    if (argc <= 1) {
        printf("morl: \e[1;31mfatal error:\e[0m no input file[s] provided\n");
        return 1;
    }

    for (int i = 1; i < argc; i++) {
        if (!read_file(argv[i])) {
            printf("morl: \e[1;31mfatal error:\e[0m failed to read %s\n", argv[i]);
            return 1;
        }

        printf("[INFO] compiling: %s\n", SRC);

        tokens toks = {0};
        if (!tokenize(&toks)) {
            printf("morl: \e[1;31mfatal error:\e[0m failed to tokenize %s\n", argv[i]);
            return 1;
        }

        stmts nodes = {0};
        if (!parse(&toks, &nodes)) {
            printf("morl: \e[1;31mfatal error:\e[0m failed to parse %s\n", argv[i]);
            return 1;
        }
    }

    return 0;
}
