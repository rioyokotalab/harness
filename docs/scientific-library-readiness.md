# Scientific-library login-surface readiness

T-228 inventories a fixed, credential-free set of scientific I/O, transform,
and linear-algebra discovery surfaces: HDF5, NetCDF, ADIOS2, FFTW, BLAS,
LAPACK, and OpenBLAS. The tracked probe checks only fixed wrapper names and
fixed `pkg-config` package identifiers. It bounds and sanitizes reported
versions, does not enumerate module catalogs or environment variables, and
does not compile, link, allocate compute, install packages, or write state.

The result is deliberately a login-environment surface, not a capability or
gap verdict. A package can exist in an unloaded site module, uenv, container,
or project environment even when this probe reports it absent. Conversely, a
visible wrapper or metadata record does not prove headers, linking, parallel
I/O, ABI compatibility, compute-node visibility, performance, or correctness.
Those require a later project-specific environment choice and scheduler-native
compile/run gate.

## 2026-07-17 bounded fleet result

The canonical record is
[`audits/scientific-library-login-surface-2026-07-17.json`](audits/scientific-library-login-surface-2026-07-17.json).
All seven probes passed and exposed `pkg-config`. The current node and RI expose
BLAS, LAPACK, OpenBLAS, and FFTW metadata in their visible login environments.
RC exposes `h5cc`, `nc-config`, and NetCDF 4.8.1 metadata. The fixed surface was
otherwise absent on AB, AB2, AL, and T4. These are observed login surfaces, not
installation gaps: the next compile/run gate must be chosen only after a
project selects its site module, uenv, container, or other environment route.
