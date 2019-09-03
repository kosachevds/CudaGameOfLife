#ifndef GPUGAMEOFLIFE_H
#define GPUGAMEOFLIFE_H

#include <vector>

const char DEAD_CELL = 0;
const char LIVING_CELL = 1;

class GpuGameHandler final
{
public:
    GpuGameHandler(int width, int height);
    ~GpuGameHandler();
    void doLifeStep(const std::vector<char>& input, std::vector<char>& output);
private:
    static constexpr int MAX_BLOCK_SIZE = 32;
    int _width;
    int _height;
    int _grid_width;
    int _grid_height;
    int _block_size;
    //int _block_height;

    char* _input;
    char* _output;
};


#endif // GPUGAMEOFLIFE_H
