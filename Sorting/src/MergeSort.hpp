#ifndef MERGE_SORT_HPP
#define MERGE_SORT_HPP

#include <vector>

namespace merge
{
	std::vector<int> sort(std::vector<int> vectorToSort);

	std::vector<int> mergeVectors(std::vector<int> left, std::vector<int> right);
	
}

#endif