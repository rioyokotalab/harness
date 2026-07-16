#include <bit>
#include <cfenv>
#include <cmath>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <limits>
#include <locale>

int main() {
    static_assert(sizeof(double) == 8);
    static_assert(std::numeric_limits<double>::is_iec559);
    if (std::fegetround() != FE_TONEAREST) return 1;

    constexpr int count = 4096;
    double forward = 0.0;
    double reverse = 0.0;
    std::int64_t integer_numerator = 0;
    for (int i = 0; i < count; ++i) {
        const int a = (i * 17) % 257 - 128;
        const int b = (i * 29) % 251 - 125;
        forward += (static_cast<double>(a) / 32.0) *
                   (static_cast<double>(b) / 64.0);
        integer_numerator += static_cast<std::int64_t>(a) * b;
    }
    for (int i = count - 1; i >= 0; --i) {
        const int a = (i * 17) % 257 - 128;
        const int b = (i * 29) % 251 - 125;
        reverse += (static_cast<double>(a) / 32.0) *
                   (static_cast<double>(b) / 64.0);
    }

    constexpr std::int64_t expected_numerator = -14036;
    constexpr double expected = -6.853515625;
    if (integer_numerator != expected_numerator || forward != expected ||
        reverse != expected || std::bit_cast<std::uint64_t>(forward) !=
                                   std::bit_cast<std::uint64_t>(reverse)) {
        return 2;
    }
    if (!std::signbit(-0.0) ||
        std::bit_cast<std::uint64_t>(std::nextafter(1.0, 2.0)) !=
            UINT64_C(0x3ff0000000000001) ||
        !std::isnan(std::numeric_limits<double>::quiet_NaN())) {
        return 3;
    }

    std::cout.imbue(std::locale::classic());
    std::cout << "numerical=pass ieee754=1 rounding=nearest numerator="
              << integer_numerator << " dot=" << std::hexfloat << forward << '\n';
    return 0;
}
