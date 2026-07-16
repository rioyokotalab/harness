#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <pthread.h>
#include <sched.h>
#include <unistd.h>

#include <cerrno>
#include <charconv>
#include <cstring>
#include <fstream>
#include <iostream>
#include <set>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace {

struct CpuTopology {
    int cpu;
    long package;
    long core;
};

long read_number(const std::string& path) {
    std::ifstream input(path);
    long value = -1;
    if (!(input >> value) || value < 0) {
        throw std::runtime_error("unavailable CPU topology metadata");
    }
    return value;
}

int parse_expected(const char* text) {
    int value = 0;
    const char* end = text + std::strlen(text);
    const auto result = std::from_chars(text, end, value);
    if (result.ec != std::errc{} || result.ptr != end || value < 2 ||
        value > CPU_SETSIZE) {
        throw std::runtime_error("expected CPUs must be an integer in [2, CPU_SETSIZE]");
    }
    return value;
}

void pin_and_verify(int cpu, int* observed) {
    cpu_set_t requested;
    CPU_ZERO(&requested);
    CPU_SET(cpu, &requested);
    const int set_status =
        pthread_setaffinity_np(pthread_self(), sizeof(requested), &requested);
    if (set_status != 0) {
        *observed = -set_status;
        return;
    }
    std::this_thread::yield();
    *observed = sched_getcpu();
}

}  // namespace

int main(int argc, char** argv) {
    try {
        if (argc != 2) {
            throw std::runtime_error("usage: affinity EXPECTED_MIN_CPUS");
        }
        const int expected = parse_expected(argv[1]);

        cpu_set_t allowed;
        CPU_ZERO(&allowed);
        if (sched_getaffinity(0, sizeof(allowed), &allowed) != 0) {
            throw std::runtime_error(std::string("sched_getaffinity failed: ") +
                                     std::strerror(errno));
        }

        const int allowed_count = CPU_COUNT(&allowed);
        const long online_count = sysconf(_SC_NPROCESSORS_ONLN);
        if (allowed_count < expected || online_count < allowed_count) {
            throw std::runtime_error("scheduler-visible CPU count is inconsistent");
        }

        std::vector<CpuTopology> topology;
        std::set<std::pair<long, long>> physical_cores;
        for (int cpu = 0; cpu < CPU_SETSIZE; ++cpu) {
            if (!CPU_ISSET(cpu, &allowed)) {
                continue;
            }
            const std::string root =
                "/sys/devices/system/cpu/cpu" + std::to_string(cpu) + "/topology/";
            const long package = read_number(root + "physical_package_id");
            const long core = read_number(root + "core_id");
            topology.push_back({cpu, package, core});
            physical_cores.emplace(package, core);
        }
        if (static_cast<int>(topology.size()) != allowed_count ||
            physical_cores.size() < 2) {
            throw std::runtime_error("fewer than two distinct physical cores are visible");
        }

        const CpuTopology* first = &topology.front();
        const CpuTopology* second = nullptr;
        for (const auto& candidate : topology) {
            if (candidate.package != first->package || candidate.core != first->core) {
                second = &candidate;
                break;
            }
        }
        if (second == nullptr) {
            throw std::runtime_error("could not select two distinct physical cores");
        }

        int observed_first = -1;
        int observed_second = -1;
        std::thread worker_first(pin_and_verify, first->cpu, &observed_first);
        std::thread worker_second(pin_and_verify, second->cpu, &observed_second);
        worker_first.join();
        worker_second.join();
        if (observed_first != first->cpu || observed_second != second->cpu ||
            observed_first == observed_second) {
            throw std::runtime_error("worker affinity placement did not hold");
        }

        std::cout << "affinity=pass allowed_cpus=" << allowed_count
                  << " online_cpus=" << online_count
                  << " physical_cores=" << physical_cores.size()
                  << " pinned_workers=2\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "affinity=fail reason=" << error.what() << '\n';
        return 2;
    }
}
