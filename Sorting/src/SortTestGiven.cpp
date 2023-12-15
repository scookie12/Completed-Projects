#include <gtest/gtest.h>

#include "BubbleSort.hpp"

#include "BigVector.hpp"

TEST(GivenWrittenTests, BubbleSort)
{
	auto ans = bubble::sort(numbers);
	EXPECT_EQ(ans, sorted);
}