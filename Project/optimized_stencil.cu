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

    //Import stencil kernel from week 4 assignment
__global__ void stencil_2d(const int *input, int *output, int N) {
    __shared__ int tile[BLOCK_SIZE + 2*Rad][BLOCK_SIZE + 2*Rad];

    int globaly = blockIdx.y * blockDim.y + threadIdx.y;
    int globalx = blockIdx.x * blockDim.x + threadIdx.x;

    int localy = threadIdx.y + Rad;
    int localx = threadIdx.x + Rad;

    // Load central tile
    if (globaly < N && globalx < N)
        tile[localy][localx] = input[IDX(globaly, globalx, N)];

    // Load halo regions
    if (threadIdx.y < Rad) {
        if (globaly >= Rad)
            tile[localy - Rad][localx] = input[IDX(globaly - Rad, globalx, N)];
        if (globaly + BLOCK_SIZE < N)
            tile[localy + BLOCK_SIZE][localx] = input[IDX(globaly + BLOCK_SIZE, globalx, N)];
    }
    if (threadIdx.x < Rad) {
        if (globalx >= Rad)
            tile[localy][localx - Rad] = input[IDX(globaly, globalx - Rad, N)];
        if (globalx + BLOCK_SIZE < N)
            tile[localy][localx + BLOCK_SIZE] = input[IDX(globaly, globalx + BLOCK_SIZE, N)];
    }

    __syncthreads();

    // Compute stencil
    if (globaly < N && globalx < N) {
        if (globaly >= Rad && globaly < N-Rad && globalx >= Rad && globalx < N-Rad) {
            int sum = 0;
            for (int dy = -Rad; dy <= Rad; dy++)
                for (int dx = -Rad; dx <= Rad; dx++)
                    sum += tile[localy + dy][localx + dx];
            output[IDX(globaly, globalx, N)] = sum / ((2*Rad+1)*(2*Rad+1));
        } else {
            output[IDX(globaly, globalx, N)] = input[IDX(globaly, globalx, N)];
        }
    }
}


// Shared memory tiled matrix multiplication kernel
__global__ void matMulKernelShared(const int *A, const int *B, int *C, int N) {
    __shared__ int tileA[BLOCK_SIZE][BLOCK_SIZE];
    __shared__ int tileB[BLOCK_SIZE][BLOCK_SIZE];

    int row = blockIdx.y * BLOCK_SIZE + threadIdx.y;
    int col = blockIdx.x * BLOCK_SIZE + threadIdx.x;
    int val = 0;

    for(int t=0; t<(N+BLOCK_SIZE-1)/BLOCK_SIZE; t++) {
        if(row < N && t*BLOCK_SIZE+threadIdx.x < N)
            tileA[threadIdx.y][threadIdx.x] = A[IDX(row, t*BLOCK_SIZE + threadIdx.x, N)];
        else
            tileA[threadIdx.y][threadIdx.x] = 0;

        if(col < N && t*BLOCK_SIZE+threadIdx.y < N)
            tileB[threadIdx.y][threadIdx.x] = B[IDX(t*BLOCK_SIZE + threadIdx.y, col, N)];
        else
            tileB[threadIdx.y][threadIdx.x] = 0;

        __syncthreads();

        for(int k=0; k<BLOCK_SIZE; k++)
            val += tileA[threadIdx.y][k] * tileB[k][threadIdx.x];

        __syncthreads();
    }

    if(row < N && col < N)
        C[IDX(row,col,N)] = val;
}

// Utility functions
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

    // Unified memory
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
    // Create streams
    cudaStream_t streamA, streamB;
    CUDA_CHECK(cudaStreamCreate(&streamA));
    CUDA_CHECK(cudaStreamCreate(&streamB));

    // Launch stencil kernels in parallel streams
    stencil_2d<<<grid, threads, 0, streamA>>>(A, As, DSIZE);
    stencil_2d<<<grid, threads, 0, streamB>>>(B, Bs, DSIZE);

    CUDA_CHECK(cudaStreamSynchronize(streamA));
    CUDA_CHECK(cudaStreamSynchronize(streamB));

    // Launch optimized matrix multiplication kernel
    matMulKernelShared<<<grid, threads>>>(As, Bs, C, DSIZE);
    CUDA_CHECK(cudaDeviceSynchronize());

    std::cout << "Checksum of C (CUDA): " << checksum(C, DSIZE) << std::endl;

    // Cleanup
    cudaFree(A);
    cudaFree(B);
    cudaFree(As);
    cudaFree(Bs);
    cudaFree(C);

    cudaStreamDestroy(streamA);
    cudaStreamDestroy(streamB);

    return 0;
}
