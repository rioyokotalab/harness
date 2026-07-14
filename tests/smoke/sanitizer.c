#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    const size_t count = 4096;
    uint32_t *values = calloc(count, sizeof(*values));
    if (values == NULL) return 2;

    uint64_t observed = 0;
    uint64_t expected = 0;
    for (size_t i = 0; i < count; ++i) {
        values[i] = (uint32_t)((i * 17U + 3U) % 101U);
        expected += (uint64_t)((i * 17U + 3U) % 101U);
    }
    for (size_t i = 0; i < count; ++i) observed += values[i];

    free(values);
    if (observed != expected) return 1;
    puts("sanitizer=pass");
    return 0;
}
