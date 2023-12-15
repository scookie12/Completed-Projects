#include <gtest/gtest.h>

#include "BubbleSort.hpp"
#include "MergeSort.hpp"
#include "SelectionSort.hpp"

#include "BigVector.hpp"
#include <iostream>



TEST(StudentTests, SmallMerge)
{
	std::vector<int> smallvector = { 2, 3, 4, 8, 1, 0 };
	std::vector<int> smallans = { 0, 1, 2, 3, 4, 8};
	auto ans = merge::sort(smallvector);
	EXPECT_EQ(ans, smallans);
}

TEST(StudentTests, SelectionSort)
{
	auto ans = selection::sort(numbers);
	EXPECT_EQ(ans, sorted);
}


TEST(StudentTests, MergeSort)
{
	auto ans = merge::sort(numbers);
	EXPECT_EQ(ans, sorted);
}