# Common high-growth cache and tool-state locations. Host environment files set
# the two roots. This file creates no directories and stays silent so it is safe
# for login and non-interactive shells.
if [ -n "${HARNESS_CACHE_ROOT:-}" ] && [ -n "${HARNESS_PERSISTENT_ROOT:-}" ]; then
    APPTAINER_CACHEDIR=$HARNESS_CACHE_ROOT/apptainer
    CARGO_HOME=$HARNESS_PERSISTENT_ROOT/tool-state/cargo
    CUDA_CACHE_PATH=$HARNESS_CACHE_ROOT/cuda
    CUPY_CACHE_DIR=$HARNESS_CACHE_ROOT/cupy
    DOTNET_CLI_HOME=$HARNESS_PERSISTENT_ROOT/tool-state/dotnet
    HF_HOME=$HARNESS_CACHE_ROOT/huggingface
    npm_config_cache=$HARNESS_CACHE_ROOT/npm
    NUGET_PACKAGES=$HARNESS_CACHE_ROOT/nuget
    PIP_CACHE_DIR=$HARNESS_CACHE_ROOT/pip
    RUSTUP_HOME=$HARNESS_PERSISTENT_ROOT/tool-state/rustup
    SINGULARITY_CACHEDIR=$HARNESS_CACHE_ROOT/singularity
    TRITON_CACHE_DIR=$HARNESS_CACHE_ROOT/triton
    UV_CACHE_DIR=$HARNESS_CACHE_ROOT/uv
    XDG_CACHE_HOME=$HARNESS_CACHE_ROOT/xdg
    export APPTAINER_CACHEDIR CARGO_HOME CUDA_CACHE_PATH CUPY_CACHE_DIR
    export DOTNET_CLI_HOME HF_HOME npm_config_cache NUGET_PACKAGES
    export PIP_CACHE_DIR RUSTUP_HOME SINGULARITY_CACHEDIR TRITON_CACHE_DIR
    export UV_CACHE_DIR XDG_CACHE_HOME
fi
