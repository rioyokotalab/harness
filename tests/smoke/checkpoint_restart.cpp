#include <algorithm>
#include <array>
#include <cerrno>
#include <charconv>
#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <fcntl.h>
#include <iomanip>
#include <iostream>
#include <limits>
#include <string_view>
#include <utility>
#include <sys/stat.h>
#include <unistd.h>

namespace {
constexpr std::array<unsigned char, 8> magic{'H', 'C', 'K', 'P', 'T', '0', '0', '1'};
constexpr std::uint32_t version = 1;
constexpr std::size_t payload_size = 32;
constexpr std::size_t checkpoint_size = 40;
constexpr std::uint64_t initial_state = 0x243f6a8885a308d3ULL;

[[noreturn]] void fail(const char* reason) {
    std::cerr << "checkpoint_restart: " << reason << '\n';
    std::exit(2);
}

std::uint64_t parse_count(std::string_view text) {
    std::uint64_t value = 0;
    const auto result = std::from_chars(text.data(), text.data() + text.size(), value);
    if (result.ec != std::errc{} || result.ptr != text.data() + text.size() ||
        value > 1000000000ULL) {
        fail("invalid-count");
    }
    return value;
}

void put_u32(unsigned char* out, std::uint32_t value) {
    for (int i = 3; i >= 0; --i) {
        out[i] = static_cast<unsigned char>(value & 0xffU);
        value >>= 8U;
    }
}

void put_u64(unsigned char* out, std::uint64_t value) {
    for (int i = 7; i >= 0; --i) {
        out[i] = static_cast<unsigned char>(value & 0xffU);
        value >>= 8U;
    }
}

std::uint32_t get_u32(const unsigned char* in) {
    std::uint32_t value = 0;
    for (int i = 0; i < 4; ++i) value = (value << 8U) | in[i];
    return value;
}

std::uint64_t get_u64(const unsigned char* in) {
    std::uint64_t value = 0;
    for (int i = 0; i < 8; ++i) value = (value << 8U) | in[i];
    return value;
}

std::uint64_t checksum(const unsigned char* data, std::size_t size) {
    std::uint64_t value = 1469598103934665603ULL;
    for (std::size_t i = 0; i < size; ++i) {
        value ^= data[i];
        value *= 1099511628211ULL;
    }
    return value;
}

std::uint64_t advance(std::uint64_t state, std::uint64_t begin,
                      std::uint64_t end) {
    for (std::uint64_t step = begin + 1; step <= end; ++step) {
        state ^= step + 0x9e3779b97f4a7c15ULL;
        state = state * 6364136223846793005ULL + 1442695040888963407ULL;
        state ^= state >> 29U;
    }
    return state;
}

bool write_all(int fd, const unsigned char* data, std::size_t size) {
    while (size != 0) {
        const ssize_t written = ::write(fd, data, size);
        if (written < 0 && errno == EINTR) continue;
        if (written <= 0) return false;
        data += static_cast<std::size_t>(written);
        size -= static_cast<std::size_t>(written);
    }
    return true;
}

void write_checkpoint(const char* path, std::uint64_t step, std::uint64_t state) {
    std::array<unsigned char, checkpoint_size> bytes{};
    std::copy(magic.begin(), magic.end(), bytes.begin());
    put_u32(bytes.data() + 8, version);
    put_u32(bytes.data() + 12, 0);
    put_u64(bytes.data() + 16, step);
    put_u64(bytes.data() + 24, state);
    put_u64(bytes.data() + payload_size, checksum(bytes.data(), payload_size));

    int flags = O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC;
#ifdef O_NOFOLLOW
    flags |= O_NOFOLLOW;
#endif
    const int fd = ::open(path, flags, S_IRUSR | S_IWUSR);
    if (fd < 0) fail("create");
    if (!write_all(fd, bytes.data(), bytes.size()) || ::fsync(fd) != 0) {
        ::close(fd);
        ::unlink(path);
        fail("write-or-fsync");
    }
    if (::close(fd) != 0) {
        ::unlink(path);
        fail("close");
    }
}

std::pair<std::uint64_t, std::uint64_t> read_checkpoint(const char* path) {
    int flags = O_RDONLY | O_CLOEXEC;
#ifdef O_NOFOLLOW
    flags |= O_NOFOLLOW;
#endif
    const int fd = ::open(path, flags);
    if (fd < 0) fail("open");
    struct stat metadata {};
    if (::fstat(fd, &metadata) != 0 || !S_ISREG(metadata.st_mode) ||
        metadata.st_size != static_cast<off_t>(checkpoint_size)) {
        ::close(fd);
        fail("size-or-type");
    }
    std::array<unsigned char, checkpoint_size> bytes{};
    std::size_t offset = 0;
    while (offset != bytes.size()) {
        const ssize_t got = ::read(fd, bytes.data() + offset, bytes.size() - offset);
        if (got < 0 && errno == EINTR) continue;
        if (got <= 0) {
            ::close(fd);
            fail("read");
        }
        offset += static_cast<std::size_t>(got);
    }
    if (::close(fd) != 0) fail("close");
    if (!std::equal(magic.begin(), magic.end(), bytes.begin())) fail("magic");
    if (get_u32(bytes.data() + 8) != version) fail("version");
    if (get_u32(bytes.data() + 12) != 0) fail("flags");
    if (get_u64(bytes.data() + payload_size) != checksum(bytes.data(), payload_size))
        fail("checksum");
    return {get_u64(bytes.data() + 16), get_u64(bytes.data() + 24)};
}

void print_final(std::uint64_t step, std::uint64_t state) {
    std::cout << "FINAL step=" << step << " state=0x" << std::hex
              << std::setw(16) << std::setfill('0') << state << '\n';
}
}  // namespace

int main(int argc, char** argv) {
    if (argc == 3 && std::string_view(argv[1]) == "reference") {
        const std::uint64_t total = parse_count(argv[2]);
        print_final(total, advance(initial_state, 0, total));
        return 0;
    }
    if (argc == 4 && std::string_view(argv[1]) == "checkpoint") {
        const std::uint64_t step = parse_count(argv[3]);
        write_checkpoint(argv[2], step, advance(initial_state, 0, step));
        std::cout << "CHECKPOINT step=" << step << " bytes=" << checkpoint_size << '\n';
        return 0;
    }
    if (argc == 5 && std::string_view(argv[1]) == "resume") {
        const std::uint64_t expected_step = parse_count(argv[3]);
        const std::uint64_t total = parse_count(argv[4]);
        const auto [step, state] = read_checkpoint(argv[2]);
        if (step != expected_step) fail("step");
        if (total < step) fail("total-before-step");
        print_final(total, advance(state, step, total));
        return 0;
    }
    fail("usage");
}
