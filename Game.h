#ifndef GAME_H
#define GAME_H

#include <array>
#include <vector>
#include <memory>
#include "gpugameoflife.h"

class Game
{
public:
    void run(int step_delay_msec, char living_mark, char dead_mark);
    static std::unique_ptr<Game> readFromFile(const std::string& filename, char living_mark);
    static std::unique_ptr<Game> createRandom(int width, int height, int required_living);
private:
    class BinarySwitch
    {
    public:
        BinarySwitch() = default;
        int getCurrent() const;
        void switchValue();
        operator int() const;
    private:
        int value { 0 };
    };

    struct TextGrid
    {
        std::vector<std::string> lines;
        int width;
        int height;

        std::vector<char> parse(char living_mark) const;
    };

    struct UniquePtrWrapper;

    std::array<std::vector<char>, 2> _grid_buffers;
    int _width;
    int _height;
    int _step_count;
    BinarySwitch _current_grid;
    GpuGameHandler _gpu;

    Game(std::vector<char>&& grid, int width, int height);

    std::vector<char>& getCurrentGrid();
    const std::vector<char>& getCurrentGrid() const;
    void doStepOnGpu();
    void print(char living_mark, char dead_mark) const;

    static void pause(int msec_duration);
    static void clearConsole();
    static Game::TextGrid readTextGrid(std::ifstream& input);
};

#endif // GAME_H
