#define NOB_IMPLEMENTATION

#include "nob.h"

#define BUILD_FOLDER "./"
#define SRC_FOLDER   "./"

int main(int argc, char **argv) {
    NOB_GO_REBUILD_URSELF(argc, argv);

    if (!nob_mkdir_if_not_exists(BUILD_FOLDER)) return 1;

    Nob_Cmd cmd = {0};

    nob_cmd_append(&cmd, "cc", "-Wall", "-Wextra", "-o", BUILD_FOLDER"mor", SRC_FOLDER"mor.c");

    nob_cc_flags(&cmd);
    nob_cc_inputs(&cmd, SRC_FOLDER"parser.c");

    if (!nob_cmd_run_sync(cmd)) return 1;

    return 0;
}
