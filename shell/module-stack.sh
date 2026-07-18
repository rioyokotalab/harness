# Source the reviewed default module stack without loading general Bash policy.
# Usage from a Bash job: . "$HOME/harness/shell/module-stack.sh" LOGICAL_HOST
harness_module_host=${1:-${HARNESS_LOGICAL_HOST:-}}
case $harness_module_host in
    local)
        if ! command -v module >/dev/null 2>&1; then
            . /etc/profile.d/modules.sh
        fi
        module unload openmpi/5.0-cuda-12.8 >/dev/null 2>&1 || true
        if ! module load openmpi/5.0-cuda-12.8; then
            unset harness_module_host
            return 1
        fi
        ;;
    ab|ab2)
        . /etc/profile.d/modules.sh
        module load hpcx cuda cudnn nccl #intel-mkl intel
        ;;
    t4)
        module use /gs/fs/tga-NII-LLM/modules/modulefiles
        module load ylab/cuda/12.8
        module load ylab/cudnn/9.7.0
        module load ylab/nccl/cuda-12.8/2.26.2
        module load ylab/hpcx/2.21.0
        ;;
    *)
        printf 'harness module stack: unsupported host: %s\n' \
            "${harness_module_host:-missing}" >&2
        unset harness_module_host
        return 2
        ;;
esac
unset harness_module_host
