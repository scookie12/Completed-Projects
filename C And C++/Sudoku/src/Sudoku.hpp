#ifndef SUDOKU_HPP
#define SUDOKU_HPP

#include <array>

const size_t SIZE = 9;

typedef std::array<std::array<size_t, SIZE>, SIZE> Board;

Board solve(Board board); // Makes sure there is a solution

bool solutionFinder(Board& board); // Driver function for solving sudoku

bool checkCol(Board board, size_t col, size_t num); // Starts at the top of a column and moves down the list, checking for repeats

bool checkRow(Board board, size_t row, size_t num); // Starts at the front of a row and moves across, checking for repeats

bool checkBox(Board board, size_t boxRow, size_t boxCol, size_t num); // Checks each 3x3 grid, checking for duplicates

bool FindBlank(Board board, size_t& row, size_t& col); // Starts in the top left corner, follows the grid until a 0 is found, returns the address

bool isSafe(Board board, size_t row, size_t col, size_t num); // A sort of preliminary check to see if a number can go in the current spot in the grid

#endif