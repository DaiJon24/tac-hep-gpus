#include <alpaka/alpaka.hpp>
#include <iostream>
#include <cstdlib>

constexpr int BLOCK_SIZE = 16;
constexpr int Rad = 3;
constexpr int DSIZE = 512;

using Dim = alpaka::DimInt<2>;
using Idx = std::size_t;
using Acc = alpaka::AccGpuCudaRt<Dim, Idx>;

struct Stencil2D
{
    template <typename TAcc>
    ALPAKA_FN_ACC void operator()(
        TAcc const &acc,
        const int *input,
        int *output,
        int N) const
    {
        auto globalIdx = alpaka::getIdx<alpaka::Grid, alpaka::Threads>(acc);
        auto localIdx  = alpaka::getIdx<alpaka::Block, alpaka::Threads>(acc);

        int y = globalIdx[0];
        int x = globalIdx[1];

        // Shared memory tile
        auto &tile =
            alpaka::declareSharedVar<int[(BLOCK_SIZE + 2*Rad)*(BLOCK_SIZE + 2*Rad)], __COUNTER__>(acc);

        int ly = localIdx[0] + Rad;
        int lx = localIdx[1] + Rad;

        if (y < N && x < N)
            tile[ly*(BLOCK_SIZE+2*Rad) + lx] = input[y*N + x];

        alpaka::syncBlockThreads(acc);

        if (y >= Rad && y < N-Rad && x >= Rad && x < N-Rad)
        {
            int sum = 0;
            for(int dy=-Rad; dy<=Rad; ++dy)
                for(int dx=-Rad; dx<=Rad; ++dx)
                    sum += tile[(ly+dy)*(BLOCK_SIZE+2*Rad) + (lx+dx)];

            output[y*N + x] = sum / ((2*Rad+1)*(2*Rad+1));
        }
        else if (y < N && x < N)
        {
            output[y*N + x] = input[y*N + x];
        }
    }
};

struct MatMulShared
{
    template <typename TAcc>
    ALPAKA_FN_ACC void operator()(
        TAcc const &acc,
        const int *A,
        const int *B,
        int *C,
        int N) const
    {
        auto globalIdx = alpaka::getIdx<alpaka::Grid, alpaka::Threads>(acc);
        auto localIdx  = alpaka::getIdx<alpaka::Block, alpaka::Threads>(acc);

        int row = globalIdx[0];
        int col = globalIdx[1];

        auto &tileA =
            alpaka::declareSharedVar<int[BLOCK_SIZE][BLOCK_SIZE], __COUNTER__>(acc);
        auto &tileB =
            alpaka::declareSharedVar<int[BLOCK_SIZE][BLOCK_SIZE], __COUNTER__>(acc);

        int val = 0;

        for (int t = 0; t < (N + BLOCK_SIZE - 1) / BLOCK_SIZE; ++t)
        {
            tileA[localIdx[0]][localIdx[1]] =
                (row < N && t*BLOCK_SIZE + localIdx[1] < N)
                ? A[row*N + t*BLOCK_SIZE + localIdx[1]]
                : 0;

            tileB[localIdx[0]][localIdx[1]] =
                (col < N && t*BLOCK_SIZE + localIdx[0] < N)
                ? B[(t*BLOCK_SIZE + localIdx[0])*N + col]
                : 0;

            alpaka::syncBlockThreads(acc);

            for(int k=0; k<BLOCK_SIZE; ++k)
                val += tileA[localIdx[0]][k] * tileB[k][localIdx[1]];

            alpaka::syncBlockThreads(acc);
        }

        if (row < N && col < N)
            C[row*N + col] = val;
    }
};

int main()
{
    using Dev = alpaka::Dev<Acc>;
    using Queue = alpaka::Queue<Dev, alpaka::Blocking>;

    Dev dev = alpaka::getDevByIdx<Acc>(0);
    Queue queue(dev);

    alpaka::Vec<Dim, Idx> extent(DSIZE, DSIZE);
    alpaka::Vec<Dim, Idx> block(BLOCK_SIZE, BLOCK_SIZE);
    alpaka::Vec<Dim, Idx> grid(
        (DSIZE + BLOCK_SIZE - 1)/BLOCK_SIZE,
        (DSIZE + BLOCK_SIZE - 1)/BLOCK_SIZE);

    auto workDiv = alpaka::WorkDivMembers<Dim, Idx>(grid, block, alpaka::Vec<Dim, Idx>::ones());
    
    auto A  = alpaka::allocBuf<int, Idx>(dev, extent);
    auto B  = alpaka::allocBuf<int, Idx>(dev, extent);
    auto As = alpaka::allocBuf<int, Idx>(dev, extent);
    auto Bs = alpaka::allocBuf<int, Idx>(dev, extent);
    auto C  = alpaka::allocBuf<int, Idx>(dev, extent);

    alpaka::exec<Acc>(queue, workDiv, Stencil2D{},
    alpaka::getPtrNative(A),
    alpaka::getPtrNative(As),
    DSIZE);

    alpaka::exec<Acc>(queue, workDiv, Stencil2D{},
    alpaka::getPtrNative(B),
    alpaka::getPtrNative(Bs),
    DSIZE);

    alpaka::wait(queue);

    alpaka::exec<Acc>(queue, workDiv, MatMulShared{},
    alpaka::getPtrNative(As),
    alpaka::getPtrNative(Bs),
    alpaka::getPtrNative(C),
    DSIZE);

    alpaka::wait(queue);
    std::cout << "Computation completed." << std::endl;
    return 0;
}