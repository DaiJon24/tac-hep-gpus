// C++ and CPU profiling 
//- Start by writing a code in C++ that :
//  - Creates two 2-dimensional square matrices A and B of size DSIZE >= 512 and fill them in with arbitrary integer values.
//  - Performs a 2-d stencil operation on each matrix. You can use any radius size, but keep it > 2.
//  - Performs a matrix multiplication of the matrices after the stencil application
//  - Make sure that you also add utility functions to check your results. 
//- Profile your C++ code using the VTune profiler and identify the compute intensive parts.

#include <iostream>
#include <vector>
#include <cstdlib>
#include <ctime>


#define DSIZE 512
#define Rad 3

using namespace std;

typedef vector<vector<int>> Matrix;
void fillMatrix(Matrix &mat) {
    for (int i = 0; i < DSIZE; ++i) {
        for (int j = 0; j < DSIZE; ++j) {
            mat[i][j] = rand() % 100; // Fill with arbitrary integer values
        }
    }
}

void stencilOperation(const Matrix &input, Matrix &output) {
    // i use an average stencil for this example to make it simple
    // Copy boundaries
    for (int i = 0; i < DSIZE; ++i) {
        for (int j = 0; j < DSIZE; ++j) {
            if (i < Rad || i >= DSIZE - Rad ||
                j < Rad || j >= DSIZE - Rad) {
                output[i][j] = input[i][j];
            }
        }
    }

    // Compute stencil for interior
    for (int i = Rad; i < DSIZE - Rad; ++i) {
        for (int j = Rad; j < DSIZE - Rad; ++j) {
            int sum = 0;
            for (int di = -Rad; di <= Rad; ++di)
                for (int dj = -Rad; dj <= Rad; ++dj)
                    sum += input[i + di][j + dj];

            output[i][j] =
                sum / ((2 * Rad + 1) * (2 * Rad + 1));
        }
    }
}


void matrixMultiply(const Matrix &A, const Matrix &B, Matrix &C) {
    for (int i = 0; i < DSIZE; ++i) {
        for (int j = 0; j < DSIZE; ++j) {
            C[i][j] = 0;
            for (int k = 0; k < DSIZE; ++k) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
}

long long checksum(const Matrix &M) {
    long long sum = 0;
    for (int i = 0; i < DSIZE; ++i)
        for (int j = 0; j < DSIZE; ++j)
            sum += M[i][j];
    return sum;
}

int main() {
    srand(time(nullptr));

    Matrix A(DSIZE, vector<int>(DSIZE));
    Matrix B(DSIZE, vector<int>(DSIZE));
    Matrix stencilA(DSIZE, vector<int>(DSIZE, 0));
    Matrix stencilB(DSIZE, vector<int>(DSIZE, 0));
    Matrix C(DSIZE, vector<int>(DSIZE, 0));

    // ---- Initialization Phase ----
    fillMatrix(A);
    fillMatrix(B);
    // ---- Stencil Phase (memory-bound) ----
    // dominant in memory access (most memory-intensive part)
    stencilOperation(A, stencilA);
    stencilOperation(B, stencilB);

    // ---- Matrix Multiplication Phase (compute-bound) ----
    // dominant in runtime (most compute-intensive part)
    matrixMultiply(stencilA, stencilB, C);

    // Optionally print a part of the result matrix C for verification
   cout << "Checksum of C: " << checksum(C) << endl;


    return 0;
}   