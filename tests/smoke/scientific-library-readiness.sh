#!/bin/sh
set -eu

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'scientific-library-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

sanitize_version() {
    value=$1
    if [ "${#value}" -le 80 ] && printf '%s\n' "$value" |
        LC_ALL=C grep -Eq '^[A-Za-z0-9][A-Za-z0-9._+(),:/ =-]*$'
    then
        printf '%s' "$value"
    else
        printf '%s' unreported
    fi
}

printf 'SCIENTIFIC_LIBRARY_SCHEMA 1\n'
printf 'HOST %s\n' "$host"
printf 'ARCH %s\n' "$(uname -m)"

for command_name in h5cc h5pcc nc-config nf-config adios2-config; do
    if command -v "$command_name" >/dev/null 2>&1; then
        printf 'WRAPPER %s present\n' "$command_name"
    else
        printf 'WRAPPER %s absent\n' "$command_name"
    fi
done

pkg_config=$(command -v pkg-config || true)
if [ -z "$pkg_config" ]; then
    printf '%s\n' 'PKG_CONFIG absent'
    for package in adios2 blas fftw3 hdf5 hdf5-openmpi lapack netcdf netcdf-fortran openblas; do
        printf 'PACKAGE %s unknown\n' "$package"
    done
else
    printf '%s\n' 'PKG_CONFIG present'
    for package in adios2 blas fftw3 hdf5 hdf5-openmpi lapack netcdf netcdf-fortran openblas; do
        if "$pkg_config" --exists "$package" 2>/dev/null; then
            version=$("$pkg_config" --modversion "$package" 2>/dev/null | sed -n '1p')
            printf 'PACKAGE %s present %s\n' "$package" "$(sanitize_version "$version")"
        else
            printf 'PACKAGE %s absent\n' "$package"
        fi
    done
fi
printf 'PASS host=%s gate=scientific-library-login-surface-v1 scope=visible-login-environment\n' "$host"
