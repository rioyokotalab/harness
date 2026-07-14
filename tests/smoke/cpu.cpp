#include <cstdint>
#include <iostream>

int main() {
    constexpr std::int64_t n = 100000;
    std::int64_t sum = 0;
#pragma omp parallel for reduction(+ : sum)
    for (std::int64_t i = 1; i <= n; ++i) sum += i;
    const std::int64_t expected = n * (n + 1) / 2;
    if (sum != expected) return 1;
    std::cout << "cpu_cpp_openmp=pass\n";
    return 0;
}
