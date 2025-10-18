#include <stdio.h>


const int DSIZE_X = 256;
const int DSIZE_Y = 256;

__global__ void add_matrix(float A[DSIZE_X][DSIZE_Y], float B[DSIZE_X][DSIZE_Y], float C[DSIZE_X][DSIZE_Y])
{
    //FIXME:
    // Express in terms of threads and blocks
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int idy = blockIdx.y * blockDim.y + threadIdx.y;
    // Add the two matrices - make sure you are not out of range
    if (idx < DSIZE_X && idy < DSIZE_Y){
        
        C[idx][idy] = A[idx][idy] + B[idx][idy];
    }

}

int main()
{

    // Create and allocate memory for host and device pointers 
    float *h_A, *h_B, *h_C, *d_A, *d_B, *d_C;
    cudaMalloc((void**)&d_A, DSIZE_X * DSIZE_Y * sizeof(float));
    cudaMalloc((void**)&d_B, DSIZE_X * DSIZE_Y * sizeof(float));
    cudaMalloc((void**)&d_C, DSIZE_X * DSIZE_Y * sizeof(float));
    h_A = new float[DSIZE_X * DSIZE_Y];
    h_B = new float[DSIZE_X * DSIZE_Y];
    h_C = new float[DSIZE_X * DSIZE_Y];

    // Fill in the matrices
    for (int i = 0; i < DSIZE_X * DSIZE_Y; i++) {
        h_A[i] = rand()/(float)RAND_MAX;
        h_B[i] = rand()/(float)RAND_MAX;
        h_C[i] = 0;
    }
    // Copy from host to device
    cudaMemcpy(d_A, h_A, DSIZE_X * DSIZE_Y * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, DSIZE_X * DSIZE_Y * sizeof(float), cudaMemcpyHostToDevice);

    // Launch the kernel
    add_matrix<<<gridSize, blockSize>>>(d_A, d_B, d_C);
    // dim3 is a built in CUDA type that allows you to define the block 
    // size and grid size in more than 1 dimentions
    // Syntax : dim3(Nx,Ny,Nz)
    dim3 blockSize(16, 16);
    dim3 gridSize((DSIZE_X + blockSize.x - 1) / blockSize.x, (DSIZE_Y + blockSize.y - 1) / blockSize.y);

    // Copy back to host
    cudaMemcpy(h_C, d_C, DSIZE_X * DSIZE_Y * sizeof(float), cudaMemcpyDeviceToHost);

    // Print and check some elements to make the addition was succesfull
    for (int i = 0; i < 10; i++) {
        int x = rand() % DSIZE_X;
        int y = rand() % DSIZE_Y;
        printf("A[%d][%d] + B[%d][%d] = C[%d][%d] -> %f + %f = %f\n", x, y, x, y, x, y, h_A[x * DSIZE_Y + y], h_B[x * DSIZE_Y + y], h_C[x * DSIZE_Y + y]);
    }
    // Free the memory
    free(h_A);
    free(h_B);
    free(h_C);
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    return 0;
}