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
