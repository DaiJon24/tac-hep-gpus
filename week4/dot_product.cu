#include <stdio.h>
#include <time.h>


#define BLOCK_SIZE 32

const int DSIZE = 256;
const int a = 1;
const int b = 1;

// error checking macro
#define cudaCheckErrors()                                       \
	do {                                                        \
		cudaError_t __err = cudaGetLastError();                 \
		if (__err != cudaSuccess) {                             \
			fprintf(stderr, "Error:  %s at %s:%d \n",           \
			cudaGetErrorString(__err),__FILE__, __LINE__);      \
			fprintf(stderr, "*** FAILED - ABORTING***\n");      \
			exit(1);                                            \
		}                                                       \
	} while (0)


// CUDA kernel that runs on the GPU
__global__ void dot_product(const int *A, const int *B, int *C, int N) {
	// Compute global thread index
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx < N) {
		// FIXME
		// Use atomicAdd
		atomicAdd(C, A[idx] * B[idx]);
	}
}


int main() {
	
	// Create the device and host pointers
	int *h_A, *h_B, *h_C, *d_A, *d_B, *d_C;

	// Fill in the host pointers 
	h_A = new int[DSIZE];
	h_B = new int[DSIZE];
	h_C = new int;
	for (int i = 0; i < DSIZE; i++){
		h_A[i] = a;
		h_B[i] = b;
	}

	*h_C = 0;


	// Allocate device memory 
	cudaMalloc((void**)&d_A, DSIZE * sizeof(int));
	cudaMalloc((void**)&d_B, DSIZE * sizeof(int));
	cudaMalloc((void**)&d_C, sizeof(int));
	
	
	// Check memory allocation for errors
	cudaCheckErrors();
	// Copy the matrices on GPU
	cudaMemcpy(d_A, h_A, DSIZE * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_B, h_B, DSIZE * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_C, h_C, sizeof(int), cudaMemcpyHostToDevice);
	

	// Check memory copy for errors
	cudaCheckErrors();
	// Define block/grid dimentions and launch kernel
	dim3 blockDim(BLOCK_SIZE);
	dim3 gridDim((DSIZE + blockDim.x - 1) / blockDim.x);
	dot_product<<<gridDim, blockDim>>>(d_A, d_B, d_C, DSIZE);
	// Copy results back to host
	cudaMemcpy(h_C, d_C, sizeof(int), cudaMemcpyDeviceToHost);
    // Check copy for errors
	cudaCheckErrors();
	// Verify result
	if (*h_C == a * b * DSIZE) {
		printf("Result is correct: %d\n", *h_C);
	} else {
		printf("Result is incorrect: %d\n", *h_C);
	}
	// Free allocated memory
	delete[] h_A;
	delete[] h_B;
	delete h_C;
	cudaFree(d_A);
	cudaFree(d_B);
	cudaFree(d_C);
	return 0;

}