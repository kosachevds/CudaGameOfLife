#include "Game.h"

int main(int argc, char* argv[])
{
    auto game = Game::createRandom(40, 20, 100);
    //auto game = Game::readFromFile("./grids/both", '1');
    game->run(250, 'o', '_');
}
