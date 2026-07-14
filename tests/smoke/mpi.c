#include <mpi.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    int rank, size, total = 0, expected_size = 2;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    if (argc == 2) {
        char *end = NULL;
        errno = 0;
        const long parsed = strtol(argv[1], &end, 10);
        if (errno != 0 || end == argv[1] || *end != '\0' || parsed < 1 ||
            parsed > INT_MAX) {
            if (rank == 0) fprintf(stderr, "expected rank count must be a positive integer\n");
            MPI_Abort(MPI_COMM_WORLD, 64);
        }
        expected_size = (int)parsed;
    } else if (argc != 1) {
        if (rank == 0) fprintf(stderr, "usage: mpi_smoke [EXPECTED_RANKS]\n");
        MPI_Abort(MPI_COMM_WORLD, 64);
    }
    if (size != expected_size) MPI_Abort(MPI_COMM_WORLD, 2);
    MPI_Reduce(&rank, &total, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
    if (rank == 0) {
        const int expected = size * (size - 1) / 2;
        if (total != expected) MPI_Abort(MPI_COMM_WORLD, 1);
        printf("mpi=pass ranks=%d\n", size);
    }
    MPI_Finalize();
    return 0;
}
