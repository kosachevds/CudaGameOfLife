#include "gpugameoflife.h"
#include <algorithm>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>

// TODO: remade with type-alias or with enum;

static int ceilDivision(int value, int divider);

__device__ int getCyclicNumber(int value, int max_value)
{
    /*return (value + max_value) % max_value;*/
    if (value >= max_value) {
        return value % max_value;
    }
    if (value < 0) {
        return max_value + value;
    }
    return value;
}

__device__ char getItem(const char* buffer, int width, int i, int j)
{
    return buffer[i * width + j];
}

__device__ void setItem(char* buffer, int width, int i, int j, char value)
{
    buffer[i * width + j] = value;
}

__device__ char getItemOnCyclicGrid(const char* grid, int width, int height, int i, int j)
{
    return getItem(grid, width,
                   getCyclicNumber(i, height),
                   getCyclicNumber(j, width));
}

__device__ int countLivingNeigbours(const char* grid, int width, int height, int i, int j)
{
    // TODO: with predefined pairs array;
    const int min_add = -1;
    const int max_add = 1;
    int count = 0;
    for (int i_add = min_add; i_add <= max_add; ++i_add) {
        int neighbor_i = getCyclicNumber(i + i_add, height);
        for (int j_add = min_add; j_add <= max_add; ++j_add) {
            if (i_add == 0 && j_add == 0) {
                continue;
            }
            int neighbor_j = getCyclicNumber(j + j_add, width);
            if (getItem(grid, width, neighbor_i, neighbor_j) == LIVING_CELL) {
                ++count;
            }
        }
    }
    return count;
}

__global__ void doLifeStep(const char* input, int width, int height, char* output)
{
    auto i = blockIdx.y * blockDim.y + threadIdx.y;
    auto j = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= height || j >= width) {
        return;
    }
    int count = countLivingNeigbours(input, width, height, i, j);
    char cell = getItem(input, width, i, j);
    if (cell == LIVING_CELL) {
        if (count < 2 || count > 3) {
            setItem(output, width, i, j, DEAD_CELL);
        } else {
            setItem(output, width, i, j, cell);
        }
    } else {
        if (count == 3) {
            setItem(output, width, i, j, LIVING_CELL);
        } else {
            setItem(output, width, i, j, cell);
        }
    }
}

GpuGameHandler::GpuGameHandler(int width, int height)
    : _width(width), _height(height)
{
    auto items_count = width * height;
    cudaMalloc(&(this->_input), items_count * sizeof(char));
    cudaMalloc(&(this->_output), items_count * sizeof(char));
    this->_block_size = std::min({ MAX_BLOCK_SIZE, width, height });
    this->_grid_height = ceilDivision(height, this->_block_size);
    this->_grid_width = ceilDivision(width, this->_block_size);
}

GpuGameHandler::~GpuGameHandler()
{
    cudaFree(this->_input);
    cudaFree(this->_output);
}

void GpuGameHandler::doLifeStep(const std::vector<char>& input, std::vector<char>& output)
{
    auto code = cudaMemcpy(this->_input, input.data(), input.size() * sizeof(char), cudaMemcpyHostToDevice);
    ::doLifeStep<<<dim3(this->_grid_width, this->_grid_height), dim3(this->_block_size, this->_block_size)>>>
        (this->_input, this->_width, this->_height, this->_output);
    code = cudaDeviceSynchronize();
    code = cudaMemcpy(output.data(), this->_output, output.size() * sizeof(char), cudaMemcpyDeviceToHost);
}

int ceilDivision(int value, int divider)
{
    return int(ceil(double(value) / divider));
}
