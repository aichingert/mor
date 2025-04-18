#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "parser.h"

char* read_file(char *file_name) {
    FILE *file = fopen(file_name, "rb");
    if (file == NULL) return NULL;

    if (fseek(file, 0, SEEK_END) != 0) return NULL;
    long len = ftell(file);
    if (fseek(file, 0, SEEK_SET) != 0) return NULL;

    char *out_src = malloc(len + 1);

    fread(out_src, len, 1, file);
    out_src[len] = '\0';
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

        if (!src) {
            printf("morl: \e[1;31mfatal error:\e[0m failed to read %s\n", argv[i]);
            return 1;
        }

        printf("[INFO] compiling: %s\n", src);

        size_t len = 0;
        token *tokens = tokenize(src, &len);

        for (size_t i = 0; i < len; i++) {
            if (tokens[i].kind == NUMERAL) {
                printf("numeral -> ");
            } else if (tokens[i].kind == PLUS) {
                printf("+ -> ");
            } else if (tokens[i].kind == LITERAL) {
                printf("lit -> ");
            } else if (tokens[i].kind == M_EOF) {
                printf("eof -> ");
            } else if (tokens[i].kind == KW_STRUCT) {
                printf("struct -> ");
            }

            printf("line: %u | from: %u - to: %u\n", tokens[i].line, tokens[i].start, tokens[i].end);
        }
    }

    return 0;
}
