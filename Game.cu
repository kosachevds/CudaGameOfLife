#include "Game.h"
#include <fstream>
#include <string>
#include <chrono>
#include <thread>
#include <iostream>

struct Game::UniquePtrWrapper : public Game
{
    UniquePtrWrapper(std::vector<char>&& grid, int width, int height)
        : Game(std::move(grid), width, height) { }
};

Game::Game(std::vector<char>&& grid, int width, int height)
    : _width(width), _height(height), _step_count(0), _gpu(width, height)
{
    auto size = width * height;
    this->_grid_buffers[this->_current_grid] = std::move(grid);
    this->_current_grid.switchValue();
    this->_grid_buffers[this->_current_grid].resize(size);
    this->_current_grid.switchValue();
}

std::vector<char>& Game::getCurrentGrid()
{
    return this->_grid_buffers[this->_current_grid];
}

const std::vector<char>& Game::getCurrentGrid() const
{
    return this->_grid_buffers[this->_current_grid];
}

void Game::doStepOnGpu()
{
    auto& current_grid = this->_grid_buffers[this->_current_grid];
    this->_current_grid.switchValue();
    auto& result_grid = this->_grid_buffers[this->_current_grid];
    this->_gpu.doLifeStep(current_grid, result_grid);
}

void Game::print(char living_mark, char dead_mark) const
{
    auto& grid = this->getCurrentGrid();
    for (int i = 0; i < int(grid.size()); ++i) {
        auto mark = (grid[i] == LIVING_CELL) ? living_mark : dead_mark;
        std::cout << mark;
        if ((i + 1) % this->_width == 0) {
            std::cout << std::endl;
        }
    }
}

void Game::pause(int msec_duration)
{
    std::this_thread::sleep_for(std::chrono::milliseconds(msec_duration));
}

void Game::clearConsole()
{
    system("cls");
}

Game::TextGrid Game::readTextGrid(std::ifstream& input)
{
    std::vector<std::string> lines;
    std::string line;
    int width = 0;
    int height = 0;
    while (std::getline(input, line)) {
        if (line.empty()) {
            continue;
        }
        int line_length = int(line.size());
        if (width == 0) {
            width = line_length;
        }
        if (line_length == width) {
            lines.push_back(line);
            ++height;
        }
    }
    return { lines, width, height };
}

void Game::run(int step_delay_msec, char living_mark, char dead_mark)
{
    while (true) {
        Game::clearConsole();
        this->_step_count++;
        this->print(living_mark, dead_mark);
        this->doStepOnGpu();
        Game::pause(step_delay_msec);
    }
}

std::unique_ptr<Game> Game::readFromFile(const std::string& filename, char living_mark)
{
    std::ifstream input(filename);
    if (!input.good()) {
        return nullptr;
    }
    auto text_grid = Game::readTextGrid(input);
    auto grid = text_grid.parse(living_mark);
    return std::make_unique<UniquePtrWrapper>(
        std::move(grid), text_grid.width, text_grid.height);
}

std::unique_ptr<Game> Game::createRandom(int width, int height, int required_living)
{
    std::vector<char> grid(width * height, DEAD_CELL);
    auto actual_living_count = 0;
    while (actual_living_count < required_living) {
        int index;
        while (true) {
            index = int(rand() % grid.size());
            if (grid[index] != LIVING_CELL) {
                break;
            }
        }
        grid[index] = LIVING_CELL;
        ++actual_living_count;
    }
    return std::make_unique<UniquePtrWrapper>(std::move(grid), width, height);
}

int Game::BinarySwitch::getCurrent() const
{
    return this->value;
}

void Game::BinarySwitch::switchValue()
{
    this->value = (value + 1) % 2;
}

Game::BinarySwitch::operator int() const
{
    return this->value;
}

std::vector<char> Game::TextGrid::parse(char living_mark) const
{
    std::vector<char> result(this->height * this->width, DEAD_CELL);
    int index = 0;
    for (auto& line: this->lines) {
        for (auto cell: line) {
            if (cell == living_mark) {
                result[index] = LIVING_CELL;
            }
            ++index;
        }
    }
    return result;
}
