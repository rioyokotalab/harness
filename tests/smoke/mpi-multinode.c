#include <mpi.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    int rank = -1;
    int size = 0;
    int name_length = 0;
    int distinct = 0;
    char name[MPI_MAX_PROCESSOR_NAME] = {0};
    char names[2 * MPI_MAX_PROCESSOR_NAME] = {0};

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    if (size != 2) MPI_Abort(MPI_COMM_WORLD, 2);
    if (MPI_Get_processor_name(name, &name_length) != MPI_SUCCESS ||
        name_length <= 0 || name_length >= MPI_MAX_PROCESSOR_NAME) {
        MPI_Abort(MPI_COMM_WORLD, 3);
    }
    name[name_length] = '\0';
    MPI_Gather(name, MPI_MAX_PROCESSOR_NAME, MPI_CHAR, names,
               MPI_MAX_PROCESSOR_NAME, MPI_CHAR, 0, MPI_COMM_WORLD);
    if (rank == 0) {
        names[MPI_MAX_PROCESSOR_NAME - 1] = '\0';
        names[2 * MPI_MAX_PROCESSOR_NAME - 1] = '\0';
        distinct = strcmp(names, names + MPI_MAX_PROCESSOR_NAME) != 0;
    }
    MPI_Bcast(&distinct, 1, MPI_INT, 0, MPI_COMM_WORLD);
    if (!distinct) MPI_Abort(MPI_COMM_WORLD, 4);
    if (rank == 0) printf("mpi_multinode=pass ranks=2 hosts=2\n");
    MPI_Finalize();
    return 0;
}
