#include <cuda_runtime.h>
#include <cstdio>

__global__ void write_answer(int *value) { *value = 42; }

int main() {
    int count = 0;
    if (cudaGetDeviceCount(&count) != cudaSuccess || count != 1) return 1;
    int *device = nullptr;
    int host = 0;
    if (cudaMalloc(&device, sizeof(int)) != cudaSuccess) return 1;
    write_answer<<<1, 1>>>(device);
    if (cudaDeviceSynchronize() != cudaSuccess) return 1;
    if (cudaMemcpy(&host, device, sizeof(int), cudaMemcpyDeviceToHost) != cudaSuccess) return 1;
    if (cudaFree(device) != cudaSuccess || host != 42) return 1;
    std::puts("cuda=pass devices=1");
    return 0;
}
