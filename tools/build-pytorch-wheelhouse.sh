#!/bin/sh
set -eu

[ "$#" -eq 3 ] || {
    printf '%s\n' 'usage: build-pytorch-wheelhouse.sh ARCH OUTPUT_ROOT CACHE_ROOT' >&2
    exit 2
}
arch=$1
output_root=$2
cache_root=$3
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
lock=$ROOT/profiles/pytorch-2.12.1-cu130.requirements.lock

case $arch in
    x86_64)
        set -- \
            --platform manylinux_2_28_x86_64 \
            --platform manylinux_2_27_x86_64 \
            --platform manylinux_2_25_x86_64 \
            --platform manylinux2014_x86_64 \
            --platform manylinux_2_18_x86_64
        ;;
    aarch64)
        set -- \
            --platform manylinux_2_28_aarch64 \
            --platform manylinux_2_27_aarch64 \
            --platform manylinux_2_25_aarch64 \
            --platform manylinux2014_aarch64 \
            --platform manylinux_2_18_aarch64 \
            --platform linux_aarch64
        ;;
    *) printf '%s\n' 'unsupported architecture' >&2; exit 2 ;;
esac
case $output_root in /*) ;; *) printf '%s\n' 'output root must be absolute' >&2; exit 2 ;; esac
case $cache_root in /*) ;; *) printf '%s\n' 'cache root must be absolute' >&2; exit 2 ;; esac
[ -d "$output_root" ] && [ ! -L "$output_root" ] || exit 2
[ -d "$cache_root" ] && [ ! -L "$cache_root" ] || exit 2
[ -f "$lock" ] && [ ! -L "$lock" ] || exit 2
[ "$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')" = 3.12 ] || {
    printf '%s\n' 'Python 3.12 is required' >&2
    exit 2
}

name=pytorch-2.12.1-cu130-cp312-$arch-wheelhouse
stage=$output_root/.$name.staging
final=$output_root/$name
[ ! -e "$stage" ] && [ ! -L "$stage" ] || exit 2
[ ! -e "$final" ] && [ ! -L "$final" ] || exit 2
mkdir -m 700 -- "$stage"

printf 'NATIVE PIP_CACHE_DIR=%s python3 -m pip download --require-hashes --no-deps --dest %s --python-version 3.12 --implementation cp --abi cp312 [platforms] -r %s\n' \
    "$cache_root" "$stage" "$lock"
PIP_CACHE_DIR=$cache_root python3 -m pip download \
    --require-hashes --no-deps --dest "$stage" \
    --python-version 3.12 --implementation cp --abi cp312 \
    "$@" -r "$lock"

set -- "$stage"/*.whl
[ "$#" -eq 29 ] || {
    printf 'unexpected wheel count: %s\n' "$#" >&2
    exit 2
}
(cd "$stage" && sha256sum ./*.whl | LC_ALL=C sort -k2) >"$stage/SHA256SUMS"
(cd "$stage" && sha256sum -c SHA256SUMS >/dev/null)
lock_sha=$(sha256sum "$lock" | awk '{ print $1 }')
{
    printf 'schema=1\n'
    printf 'python=3.12\n'
    printf 'torch=2.12.1+cu130\n'
    printf 'cuda=13.0\n'
    printf 'architecture=%s\n' "$arch"
    printf 'lock_sha256=%s\n' "$lock_sha"
    printf 'wheel_count=29\n'
} >"$stage/ARTIFACT"
chmod 444 "$stage"/*.whl "$stage/SHA256SUMS" "$stage/ARTIFACT"
chmod 555 "$stage"
mv -- "$stage" "$final"
printf 'ARTIFACT path=%s architecture=%s wheels=29 lock_sha256=%s status=verified\n' \
    "$final" "$arch" "$lock_sha"
