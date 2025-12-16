#include <iostream>
#include <cstdlib>
#include <cuda_runtime.h>

#define DSIZE 512
#define Rad 3
#define BLOCK_SIZE 16

#define IDX(i,j,N) ((i)*(N) + (j))

// Error checking macro

#define CUDA_CHECK(err) \
    if (err != cudaSuccess) { \
        std::cerr << "CUDA Error: " << cudaGetErrorString(err) \
                  << " at line " << __LINE__ << std::endl; \
        exit(EXIT_FAILURE); \
    }


__global__ void stencilKernel(const int *input, int *output, int N) {
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    int j = blockIdx.x * blockDim.x + threadIdx.x;

    if (i >= N || j >= N) return;

    // boundary
    if (i < Rad || i >= N - Rad ||
        j < Rad || j >= N - Rad) {
        output[IDX(i,j,N)] = input[IDX(i,j,N)];
        return;
    }

    int sum = 0;
    for (int di = -Rad; di <= Rad; ++di)
        for (int dj = -Rad; dj <= Rad; ++dj)
            sum += input[IDX(i+di, j+dj, N)];

    int size = (2*Rad + 1) * (2*Rad + 1);
    output[IDX(i,j,N)] = sum / size;
}


__global__ void matMulKernel(const int *A, const int *B, int *C, int N) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row >= N || col >= N) return;

    int val = 0;
    for (int k = 0; k < N; ++k)
        val += A[IDX(row,k,N)] * B[IDX(k,col,N)];

    C[IDX(row,col,N)] = val;
}


void fillMatrix(int *M, int N) {
    for (int i = 0; i < N*N; i++)
        M[i] = rand() % 100;
}

long long checksum(const int *M, int N) {
    long long sum = 0;
    for (int i = 0; i < N*N; i++)
        sum += M[i];
    return sum;
}

int main() {
    srand(0);

    size_t bytes = DSIZE * DSIZE * sizeof(int);

    // Host memory
    int *A, *B, *As, *Bs, *C;
    CUDA_CHECK(cudaMallocManaged(&A, bytes));
    CUDA_CHECK(cudaMallocManaged(&B, bytes));
    CUDA_CHECK(cudaMallocManaged(&As, bytes));
    CUDA_CHECK(cudaMallocManaged(&Bs, bytes));
    CUDA_CHECK(cudaMallocManaged(&C, bytes));

    fillMatrix(A, DSIZE);
    fillMatrix(B, DSIZE);

    dim3 threads(BLOCK_SIZE, BLOCK_SIZE);
    dim3 grid((DSIZE + BLOCK_SIZE - 1) / BLOCK_SIZE,
              (DSIZE + BLOCK_SIZE - 1) / BLOCK_SIZE);

    // Stencil
    stencilKernel<<<grid, threads>>>(A, As, DSIZE);
    stencilKernel<<<grid, threads>>>(B, Bs, DSIZE);

    // Matrix multiply
    matMulKernel<<<grid, threads>>>(As, Bs, C, DSIZE);
    CUDA_CHECK(cudaDeviceSynchronize());

    
    std::cout << "Checksum of C (CUDA): " << checksum(C, DSIZE) << std::endl;
    // Cleanup
    cudaFree(A);
    cudaFree(B);
    cudaFree(As);
    cudaFree(Bs);
    cudaFree(C);

    return 0;
}
