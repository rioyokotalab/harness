#include <array>
#include <concepts>
#include <iostream>
#include <span>

template <std::integral Value>
Value sum(std::span<const Value> values) {
    Value result{};
    for (const Value value : values) result += value;
    return result;
}

int main() {
    constexpr std::array<int, 4> values{1, 2, 3, 4};
    if (sum<int>(values) != 10) return 1;
    std::cout << "cpp20=pass\n";
    return 0;
}
