#if defined(__GNUC__) || defined(__clang__)
__attribute__((noinline))
#endif
int checkpoint(int value) {
    volatile int local = value + 7;
    return local;
}

int main(void) { return checkpoint(35) == 42 ? 0 : 1; }
