# Common high-growth cache and tool-state locations. Host environment files set
# the two roots. This file creates no directories and stays silent so it is safe
# for login and non-interactive shells.
if [ -n "${HARNESS_CACHE_ROOT:-}" ] && [ -n "${HARNESS_PERSISTENT_ROOT:-}" ]; then
    XDG_CACHE_HOME=$HARNESS_CACHE_ROOT/xdg
    PIP_CACHE_DIR=$HARNESS_CACHE_ROOT/pip
    UV_CACHE_DIR=$HARNESS_CACHE_ROOT/uv
    npm_config_cache=$HARNESS_CACHE_ROOT/npm
    CUDA_CACHE_PATH=$HARNESS_CACHE_ROOT/cuda
    CUPY_CACHE_DIR=$HARNESS_CACHE_ROOT/cupy
    TRITON_CACHE_DIR=$HARNESS_CACHE_ROOT/triton
    APPTAINER_CACHEDIR=$HARNESS_CACHE_ROOT/apptainer
    SINGULARITY_CACHEDIR=$HARNESS_CACHE_ROOT/singularity
    DOTNET_CLI_HOME=$HARNESS_PERSISTENT_ROOT/tool-state/dotnet
    NUGET_PACKAGES=$HARNESS_CACHE_ROOT/nuget
    CARGO_HOME=$HARNESS_PERSISTENT_ROOT/tool-state/cargo
    RUSTUP_HOME=$HARNESS_PERSISTENT_ROOT/tool-state/rustup
    export XDG_CACHE_HOME PIP_CACHE_DIR UV_CACHE_DIR npm_config_cache
    export CUDA_CACHE_PATH CUPY_CACHE_DIR TRITON_CACHE_DIR
    export APPTAINER_CACHEDIR SINGULARITY_CACHEDIR
    export DOTNET_CLI_HOME NUGET_PACKAGES CARGO_HOME RUSTUP_HOME
fi
