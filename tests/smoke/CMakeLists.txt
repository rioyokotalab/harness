cmake_minimum_required(VERSION 3.20)
project(harness_cpu_smoke LANGUAGES C CXX Fortran)

find_package(OpenMP REQUIRED COMPONENTS CXX)

add_executable(cpu_c cpu.c)
add_executable(cpu_cpp cpu.cpp)
target_link_libraries(cpu_cpp PRIVATE OpenMP::OpenMP_CXX)
add_executable(cpu_fortran cpu.f90)

enable_testing()
add_test(NAME cpu_c COMMAND cpu_c)
add_test(NAME cpu_cpp_openmp COMMAND cpu_cpp)
set_tests_properties(cpu_cpp_openmp PROPERTIES ENVIRONMENT "OMP_NUM_THREADS=2")
add_test(NAME cpu_fortran COMMAND cpu_fortran)
