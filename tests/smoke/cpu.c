#include <stdint.h>
#include <stdio.h>

int main(void) {
    const uint64_t n = 100000;
    uint64_t sum = 0;
    for (uint64_t i = 1; i <= n; ++i) sum += i;
    const uint64_t expected = n * (n + 1) / 2;
    if (sum != expected) return 1;
    puts("cpu_c=pass");
    return 0;
}
