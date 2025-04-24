#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#define NOB_IMPLEMENTATION
#include "nob.h"
#include "parser.h"

char* read_file(char *file_name) {
    FILE *file = fopen(file_name, "rb");

    if (file == NULL) return NULL;
    if (fseek(file, 0, SEEK_END) != 0) return NULL;
    long file_size = ftell(file);
    if (fseek(file, 0, SEEK_SET) != 0) return NULL;

    char *out_src = malloc(file_size + 1);

    fread(out_src, file_size, 1, file);
    out_src[file_size] = 0;
    fclose(file);

    return out_src;
}

int main(int argc, char **argv) {
    if (argc <= 1) {
        printf("morl: \e[1;31mfatal error:\e[0m no input file[s] provided\n");
        return 1;
    }

    for (int i = 1; i < argc; i++) {
        char *src = read_file(argv[i]);

        if (src == NULL) {
            printf("morl: \e[1;31mfatal error:\e[0m failed to read %s\n", argv[i]);
            return 1;
        }

        printf("[INFO] compiling: %s\n", src);

        tokens toks = {0};
        if (!tokenize(src, &toks)) {
            printf("morl: \e[1;31mfatal error:\e[0m failed to tokenize %s\n", argv[i]);
            return 1;
        }

        stmts nodes = {0};
        if (!parse(src, &toks, &nodes)) {
            printf("morl: \e[1;31mfatal error:\e[0m failed to parse %s\n", argv[i]);
            return 1;
        }
    }

    return 0;
}
