#include <stdio.h>


const int DSIZE = 40960;
const int block_size = 256;
const int grid_size = DSIZE/block_size;


__global__ void vector_addition(float *array_A, float *array_B) {

    //FIXME:
    // Express the vector index in terms of threads and blocks
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    // Swap the vector elements - make sure you are not out of range
    if (idx < DSIZE) {
        float temp = array_A[idx];
        array_A[idx] = array_B[idx];
        array_B[idx] = temp;
    }

}


int main() {


    float *h_A, *h_B, *h_C, *d_A, *d_B, *d_C;
    h_A = new float[DSIZE];
    h_B = new float[DSIZE];
    h_C = new float[DSIZE];


    for (int i = 0; i < DSIZE; i++) {
        h_A[i] = rand()/(float)RAND_MAX;
        h_B[i] = rand()/(float)RAND_MAX;
        h_C[i] = 0;
    }


    // Allocate memory for host and device pointers 
    cudaMalloc((void**)&d_A, DSIZE * sizeof(float));
    cudaMalloc((void**)&d_B, DSIZE * sizeof(float));
    cudaMalloc((void**)&d_C, DSIZE * sizeof(float));
    // Copy from host to device
    cudaMemcpy(d_A, h_A, DSIZE * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, DSIZE * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_C, h_C, DSIZE * sizeof(float), cudaMemcpyHostToDevice);
    // Launch the kernel
    vector_addition<<<grid_size, block_size>>>(d_A, d_B);
    // Copy back to host
    cudaMemcpy(h_A, d_A, DSIZE * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(h_B, d_B, DSIZE * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(h_C, d_C, DSIZE * sizeof(float), cudaMemcpyDeviceToHost);
    // Print and check some elements to make sure swapping was successfull
    for (int i = 0; i < 10; i++) {
        printf("A[%d] = %f, B[%d] = %f\n", i, h_A[i], i, h_B[i]);
    }
    // Free the memory 
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    free(h_A);
    free(h_B);
    free(h_C);

    return 0;
}
