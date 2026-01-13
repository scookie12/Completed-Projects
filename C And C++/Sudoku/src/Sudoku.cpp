#include "Sudoku.hpp"
#include <stdexcept>


Board solve(Board board) 
{
	if (solutionFinder(board))
		return board;
	else
		throw std::runtime_error("Solution Does Not Exist");
}

bool solutionFinder(Board& board)
{
	size_t row, col;

	if (!FindBlank(board, row, col))
		return true;

	for (size_t num = 1; num <= 9; num++) {
		if (isSafe(board, row, col, num)) {
			board[row][col] = num;

			if (solutionFinder(board))
				return true;
			board[row][col] = 0;
		}
	}
	return false;
}

bool checkCol(Board board, size_t col, size_t num) 
{
	for (size_t row = 0; row < SIZE; row++)
		if (board[row][col] == num)
			return true;
	return false;
}

bool checkRow(Board board, size_t row, size_t num)
{
	for (size_t col = 0; col < SIZE; col++)
		if (board[row][col] == num)
			return true;
	return false;
}

bool checkBox(Board board, size_t boxRow, size_t boxCol, size_t num) 
{
	for (size_t row = 0; row < 3; row++)
		for (size_t col = 0; col < 3; col++)
			if (board[row + boxRow][col + boxCol] == num)
				return true;
	return false;
}

bool FindBlank(Board board, size_t& row, size_t& col)
{
	for (row = 0; row < SIZE; row++)
		for (col = 0; col < SIZE; col++)
			if (board[row][col] == 0)
				return true;
	return false;
}

bool isSafe(Board board, size_t row, size_t col, size_t num)
{
	return !checkRow(board, row, num) &&
		!checkCol(board, col, num) &&
		!checkBox(board, row - row % 3, col - col % 3, num) &&
		board[row][col] == 0; 
}