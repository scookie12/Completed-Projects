
#include <gtest/gtest.h>

#include "Sudoku.hpp"

TEST(GivenWrittenTests, Test1)
{
    Board board = { {{0, 0, 0, 0, 3, 0, 6, 4, 0},
                    {0, 3, 0, 7, 0, 5, 8, 0, 0},
                    {8, 2, 0, 0, 9, 6, 0, 7, 0},
                    {0, 0, 0, 0, 7, 0, 2, 9, 6},
                    {0, 0, 3, 4, 2, 9, 0, 1, 0},
                    {2, 9, 8, 5, 6, 1, 4, 0, 7},
                    {7, 0, 2, 9, 0, 0, 0, 0, 0},
                    {0, 0, 0, 0, 0, 0, 0, 6, 4},
                    {4, 5, 9, 0, 0, 0, 7, 0, 0}} };
    Board response = solve(board);

    Board answer = { {{5, 1, 7, 8, 3, 2, 6, 4, 9},
                     {9, 3, 6, 7, 4, 5, 8, 2, 1},
                     {8, 2, 4, 1, 9, 6, 3, 7, 5},
                     {1, 4, 5, 3, 7, 8, 2, 9, 6},
                     {6, 7, 3, 4, 2, 9, 5, 1, 8},
                     {2, 9, 8, 5, 6, 1, 4, 3, 7},
                     {7, 6, 2, 9, 8, 4, 1, 5, 3},
                     {3, 8, 1, 2, 5, 7, 9, 6, 4},
                     {4, 5, 9, 6, 1, 3, 7, 8, 2}} };
    EXPECT_EQ(response, answer);
}

TEST(GivenWrittenTests, Test2)
{
    Board board = { {{8, 3, 0, 0, 0, 0, 1, 0, 2},
                    {1, 0, 7, 3, 0, 8, 0, 0, 0},
                    {0, 0, 0, 5, 1, 0, 3, 0, 0},
                    {0, 0, 0, 0, 0, 4, 0, 0, 0},
                    {4, 5, 6, 2, 8, 3, 0, 0, 0},
                    {0, 0, 0, 0, 0, 5, 0, 6, 4},
                    {7, 0, 0, 0, 0, 0, 4, 0, 0},
                    {0, 9, 4, 0, 3, 1, 6, 0, 0},
                    {3, 0, 2, 4, 0, 0, 0, 0, 5}} };
    Board response = solve(board);

    Board answer = { {{8, 3, 5, 6, 4, 9, 1, 7, 2},
                     {1, 4, 7, 3, 2, 8, 5, 9, 6},
                     {6, 2, 9, 5, 1, 7, 3, 4, 8},
                     {9, 8, 1, 7, 6, 4, 2, 5, 3},
                     {4, 5, 6, 2, 8, 3, 7, 1, 9},
                     {2, 7, 3, 1, 9, 5, 8, 6, 4},
                     {7, 6, 8, 9, 5, 2, 4, 3, 1},
                     {5, 9, 4, 8, 3, 1, 6, 2, 7},
                     {3, 1, 2, 4, 7, 6, 9, 8, 5}} };
    EXPECT_EQ(response, answer);
}

TEST(GivenWrittenTests, Test3)
{
    Board board = { {{0, 6, 0, 7, 0, 0, 0, 0, 0},
                    {3, 0, 2, 5, 0, 0, 8, 0, 0},
                    {1, 0, 0, 0, 0, 0, 0, 2, 4},
                    {0, 0, 0, 0, 2, 0, 9, 0, 0},
                    {8, 0, 1, 0, 0, 4, 2, 7, 0},
                    {0, 0, 0, 1, 0, 7, 0, 0, 0},
                    {0, 0, 0, 0, 0, 0, 3, 0, 0},
                    {7, 0, 0, 8, 5, 0, 6, 0, 0},
                    {0, 0, 0, 0, 0, 0, 0, 4, 9}} };
    Board response = solve(board);

    Board answer = { {{5, 6, 8, 7, 4, 2, 1, 9, 3},
                     {3, 4, 2, 5, 9, 1, 8, 6, 7},
                     {1, 9, 7, 3, 6, 8, 5, 2, 4},
                     {4, 7, 3, 6, 2, 5, 9, 8, 1},
                     {8, 5, 1, 9, 3, 4, 2, 7, 6},
                     {9, 2, 6, 1, 8, 7, 4, 3, 5},
                     {2, 1, 9, 4, 7, 6, 3, 5, 8},
                     {7, 3, 4, 8, 5, 9, 6, 1, 2},
                     {6, 8, 5, 2, 1, 3, 7, 4, 9}} };
    EXPECT_EQ(response, answer);
}