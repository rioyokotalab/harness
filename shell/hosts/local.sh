# The current node's MPI compiler is supplied by a reviewed site module rather
# than the base PATH. Keep an already selected MPI toolchain; otherwise load
# the same Open MPI route used by tracked batch jobs. Batch jobs still source
# module-stack.sh explicitly so they do not depend on interactive inheritance.
if ! command -v mpicc >/dev/null 2>&1; then
    if [ ! -r "$HOME/harness/shell/module-stack.sh" ] ||
        ! . "$HOME/harness/shell/module-stack.sh" local >/dev/null 2>&1; then
        printf '%s\n' \
            'harness: local MPI module unavailable; mpicc remains off PATH' >&2
    fi
fi
